# frozen_string_literal: true

module Legion
  module Extensions
    module Factory
      module Helpers
        module SpecParser
          module_function

          def parse(file_path:)
            return { success: false, error: 'file not found' } unless ::File.exist?(file_path)

            content = ::File.read(file_path)
            title = extract_title(content)
            sections = extract_sections(content)
            code_blocks = extract_code_blocks(content)

            {
              success:     true,
              file_path:   file_path,
              title:       title,
              sections:    sections,
              code_blocks: code_blocks,
              raw:         content
            }
          rescue StandardError => e
            { success: false, error: e.message }
          end

          def raw_content(file_path:)
            ::File.read(file_path)
          end

          def extract_title(content)
            match = content.match(/^#\s+(.+)$/)
            match ? match[1].strip : 'Untitled'
          end

          def extract_sections(content)
            sections = []
            current_heading = nil
            current_items = []

            content.each_line do |line|
              if line =~ /^##\s+(.+)$/
                sections << { heading: current_heading, items: current_items } if current_heading
                current_heading = Regexp.last_match(1).strip
                current_items = []
              elsif current_heading && line =~ /^[-*]\s+(.+)$/
                current_items << Regexp.last_match(1).strip
              end
            end

            sections << { heading: current_heading, items: current_items } if current_heading
            sections
          end

          def extract_code_blocks(content)
            blocks = []
            content.scan(/```(\w*)\n(.*?)```/m) do |lang, code|
              blocks << { language: lang.empty? ? nil : lang, code: code.strip }
            end
            blocks
          end

          private_class_method :extract_title, :extract_sections, :extract_code_blocks
        end
      end
    end
  end
end
