require 'fileutils'
require_relative '../cmd'
include PmdTester
module PmdTester
  # Building pmd xml reports according to a list of standard
  # projects and branch of pmd source code
  class PmdReportBuilder
    def initialize(branch_config, projects, local_git_repo, pmd_branch_name)
      @branch_config = branch_config
      @projects = projects
      @local_git_repo = local_git_repo
      @pmd_branch_name = pmd_branch_name
      @pwd = Dir.getwd

      @pmd_branch_details = PmdBranchDetail.new
      @pmd_branch_details.branch_name = pmd_branch_name
      @pmd_branch_details.branch_config = branch_config
    end

    def create_repositories_dir
      @repositories_dir = "#{@pwd}/target/repositories"
      FileUtils.mkdir_p(@repositories_dir) unless File.directory?(@repositories_dir)
    end

    def execute_reset_cmd(type, tag)
      case type
      when 'git'
        reset_cmd = "git reset --hard #{tag}"
      when 'hg'
        reset_cmd = "hg up #{tag}"
      else
        raise Exception, "Unknown #{type} repository"
      end

      Cmd.execute(reset_cmd)
    end

    def get_projects
      puts 'Cloning projects started'

      create_repositories_dir

      @projects.each do |project|
        path = "#{@repositories_dir}/#{project.name}"
        clone_cmd = "#{project.type} clone #{project.connection} #{path}"
        if File.exist?(path)
          puts "Skipping clone, project path #{path} already exists"
        else
          Cmd.execute(clone_cmd)
        end
        project.local_path = path

        next if project.tag.nil?
        Dir.chdir(path) do
          execute_reset_cmd(project.type, project.tag)
        end
      end
    end

    def get_pmd_binary_file
      Dir.chdir(@local_git_repo) do
        checkout_cmd = "git checkout #{@pmd_branch_name}"
        Cmd.execute(checkout_cmd)

        @pmd_branch_details.branch_last_sha = get_last_commit_sha
        @pmd_branch_details.branch_last_message = get_last_commit_message

        package_cmd = './mvnw clean package -Dpmd.skip=true -Dmaven.test.skip=true' \
                      ' -Dmaven.checkstyle.skip=true -Dmaven.javadoc.skip=true'
        Cmd.execute(package_cmd)

        version_cmd = "./mvnw -q -Dexec.executable=\"echo\" -Dexec.args='${project.version}' " \
                      '--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec'
        @pmd_version = Cmd.execute(version_cmd)

        target_dir = "#{@pwd}/target"
        unzip_cmd = "unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip -d #{target_dir}"
        Cmd.execute(unzip_cmd)
      end
    end

    def get_last_commit_sha
      get_last_commit_sha_cmd = 'git rev-parse HEAD'
      Cmd.execute(get_last_commit_sha_cmd)
    end

    def get_last_commit_message
      get_last_commit_message_cmd = 'git log -1 --pretty=%B'
      Cmd.execute(get_last_commit_message_cmd)
    end

    def generate_pmd_report(src_root_dir, report_file)
      run_path = "target/pmd-bin-#{@pmd_version}/bin/run.sh"
      pmd_cmd = "#{run_path} pmd -d #{src_root_dir} -f xml -R #{@branch_config} " \
                "-r #{report_file} -failOnViolation false"
      start_time = Time.now
      Cmd.execute(pmd_cmd)
      end_time = Time.now
      end_time - start_time
    end

    def generate_pmd_reports
      puts "Generating pmd Report started -- branch #{@pmd_branch_name}"

      get_pmd_binary_file

      pmd_branch_name = @pmd_branch_name.delete('/')
      branch_file = "target/reports/#{pmd_branch_name}"
      FileUtils.mkdir_p(branch_file) unless File.directory?(branch_file)

      sum_time = 0
      @projects.each do |project|
        project_report_file = "#{branch_file}/#{project.name}.xml"
        project_source_dir = "target/repositories/#{project.name}"
        execution_time = generate_pmd_report(project_source_dir, project_report_file)
        pmd_report_details = PmdReportDetail.new(project_report_file, execution_time)
        project.pmd_reports.store(@pmd_branch_name, pmd_report_details)
        sum_time += execution_time
      end
      @pmd_branch_details.execution_time = sum_time

      @pmd_branch_details
    end

    def build
      get_projects
      generate_pmd_reports
    end
  end

  # This class represents all details about branch of pmd
  class PmdBranchDetail
    attr_accessor :branch_config
    attr_accessor :branch_last_sha
    attr_accessor :branch_last_message
    attr_accessor :branch_name
    attr_accessor :execution_time
  end

  # This class represents all details about report of pmd
  class PmdReportDetail
    attr_reader :file_path
    attr_reader :execution_time

    def initialize(file_path, execution_time)
      @file_path = file_path
      @execution_time = execution_time
    end
  end
end
