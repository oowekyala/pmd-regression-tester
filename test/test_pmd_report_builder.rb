require 'test/unit'
require_relative '../lib/pmdtester/builders/pmd_report_builder'
require_relative '../lib/pmdtester/parsers/projects_parser'
include PmdTester

class TestPmdReportBuilder < Test::Unit::TestCase
  def test_build
    Process.fork do
      projects = ProjectsParser.new("test/resources/project-test.xml").parse
      builder = PmdReportBuilder.new('config/all-java.xml', projects, 'target/repositories/pmd','pmd_releases/6.2.0')
      builder.build
    end
    Process.wait

    assert_equal(0, $?.exitstatus)
  end
end