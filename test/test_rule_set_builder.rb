# frozen_string_literal: true

require 'test_helper'

# The unit test class for RuleSetBuilder
class TestRuleSetBuilder < Test::Unit::TestCase
  PATH_TO_TEST_RESOURCES = 'test/resources/rule_set_builder'
  include PmdTester
  def mock_build(diff_filenames, filter_set)
    options = mock
    options.expects(:local_git_repo).returns('.')
    options.expects(:base_branch).returns('base_branch')
    options.expects(:patch_branch).returns('patch_branch')
    options.expects(:filter_set=).with(filter_set)
    options.expects(:base_config=).returns('')
    options.expects(:patch_config=).returns('')
    builder = RuleSetBuilder.new(options)
    Cmd.expects(:execute).returns(diff_filenames)
    builder.build
  end

  def test_build_design_codestyle_config
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/UnnecessaryReturnValueRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/UnnecessaryConstructorRule.java
    DOC
    mock_build(diff_filenames, Set['design', 'codestyle'])

    expected = File.read("#{PATH_TO_TEST_RESOURCES}/expected-design-codestyle.xml")
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_build_all_rulesets_config
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/UnnecessaryConstructorRule.java
      pmd-core/src/main/java/net/sourceforge/pmd/lang/rule/xpath/SaxonXPathRuleQuery.java
    DOC
    mock_build(diff_filenames, nil)

    expected = File.read("#{PATH_TO_TEST_RESOURCES}/expected-all-java.xml")
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end
end
