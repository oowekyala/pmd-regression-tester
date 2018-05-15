require 'test/unit'
require_relative '../lib/pmdtester/parsers/projects_parser'

class TestProjectsParser < Test::Unit::TestCase
  def test_project_parser
    projects = PmdTester::ProjectsParser.new("test/resources/project-list.xml").parse
    assert_equal(3, projects.size)

    expected_exclude_pattern = %w[**/src/test/resources-noncompilable/**/* **/src/test/resources/**/*]
    assert_equal(expected_exclude_pattern, projects[0].exclude_pattern)

    assert_equal("openjdk10", projects[1].name)
    assert_equal("hg", projects[1].type)
    assert_equal("http://hg.openjdk.java.net/jdk10/jdk10/jdk", projects[1].connection)
    assert_equal("http://hg.openjdk.java.net/jdk10/jdk10/jdk/file/777356696811", projects[1].webview_url)
    assert_nil( projects[1].tag)
    assert_empty(projects[1].exclude_pattern)

    assert_equal("spring-framework", projects[2].name)
    assert_equal("git", projects[2].type)
    assert_equal("https://github.com/spring-projects/spring-framework", projects[2].connection)
    assert_nil( projects[2].webview_url)
    assert_equal("v5.0.6.RELEASE", projects[2].tag)
    assert_empty(projects[2].exclude_pattern)
  end

  def test_invalid_list
    list_file = "test/resources/project-list-invalid.xml"
    begin
      projects = PmdTester::ProjectsParser.new(list_file).parse
    rescue PmdTester::ProjectsParserException => e
      assert_equal("Schema validate failed: In #{list_file}", e.message)
      assert_equal("10:0: ERROR: Element 'tag': This element is not expected. " +
                       "Expected is ( connection ).", e.errors[0].to_s)
      assert_equal("15:0: ERROR: Element 'connection': This element is not expected. " +
                       "Expected is ( type ).", e.errors[1].to_s)
    end
  end
end