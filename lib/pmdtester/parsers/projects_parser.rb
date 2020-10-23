# frozen_string_literal: true

require 'nokogiri'

module PmdTester
  # The ProjectsParser is a class responsible of parsing
  # the projects XML file to get the Project object array
  class ProjectsParser
    def parse(list_file)
      schema = Nokogiri::XML::Schema(File.read(schema_file_path))
      document = Nokogiri::XML(File.read(list_file))

      errors = schema.validate(document)
      unless errors.empty?
        raise ProjectsParserException.new(errors), "Schema validate failed: In #{list_file}"
      end

      projects = []
      document.xpath('//project').each do |project|
        projects.push(Project.new(project))
      end
      projects
    end

    def schema_file_path
      ResourceLocator.locate('config/projectlist_1_1_0.xsd')
    end
  end

  # When this exception is raised, it means that
  # schema validate of 'project-list' xml file failed
  class ProjectsParserException < RuntimeError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end
end
