# frozen_string_literal: true

module PmdTester
  # This class is the parent of all classes which is used to build html report
  class HtmlReportBuilder
    CSS_SRC_DIR = ResourceLocator.locate('resources/css')
    NO_DIFFERENCES_MESSAGE = 'No differences found!'

    def build_html_report(title_name)
      html_builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html do
          build_head(doc, title_name)
          build_body(doc)
        end
      end
      html_builder.to_html
    end

    def build_head(doc, title_name)
      doc.head do
        doc.title title_name

        doc.style(type: 'text/css', media: 'all') do
          doc.text '@import url("./css/maven-base.css");@import url("./css/maven-theme.css");'
        end
      end
    end

    def build_table_head(doc, *columns)
      doc.thead do
        doc.tr do
          columns.each do |column|
            doc.th column
          end
        end
      end
    end

    def build_table_anchor_column(doc, prefix, index)
      doc.td do
        doc.a(id: "#{prefix}#{index}", href: "##{prefix}#{index}") { doc.text '#' }
      end
    end

    def copy_css(report_dir)
      css_dest_dir = "#{report_dir}/css"
      FileUtils.copy_entry(CSS_SRC_DIR, css_dest_dir)
    end

    def build_table_content_for(doc, removed_size, new_size)
      doc.font(color: 'red') { doc.text "-#{removed_size}" }
      doc.text ' | '
      doc.font(color: 'green') { doc.text "+#{new_size}" }
    end
  end
end
