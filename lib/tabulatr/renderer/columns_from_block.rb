#--
# Copyright (c) 2010-2014 Peter Horn & Florian Thomas, metaminded UG
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class Tabulatr::Renderer
  class ColumnsFromBlock
    attr_accessor :columns, :klass, :table_data, :filters

    def initialize(klass, table_data_object)
      @klass = klass
      @table_data = table_data_object
      @columns ||= []
      @filters ||= []
    end

    def column(name, opts={}, &block)
      if table_data
        @columns << fetch_column_from_table_data(klass.table_name.to_sym, name, opts, &block)
      else
        @columns << Column.from(klass: klass, table_name: klass.table_name.to_sym, name: name, col_options: Tabulatr::ParamsBuilder.new(opts), &block)
      end
    end

    def association(table_name, name, opts={}, &block)
      if table_data
        @columns << fetch_column_from_table_data(table_name, name, opts, &block)
      else
        assoc_klass = klass.reflect_on_association(table_name.to_sym)
        @columns << Association.from(klass: assoc_klass.try(:klass),
          name: name, table_name: table_name, col_options: Tabulatr::ParamsBuilder.new(opts), &block)
      end
    end

    def checkbox(opts={})
      @columns << Checkbox.from(klass: klass, col_options: Tabulatr::ParamsBuilder.new(opts.merge(filter: false, sortable: false)))
    end

    def action(opts={}, &block)
      @columns << Action.from(klass: klass, col_options: Tabulatr::ParamsBuilder.new(opts.merge(filter: false, sortable: false)), &block)
    end

    def buttons(opts={}, &block)
      output = ->(r) {
        bb = self.instance_exec Tabulatr::Data::ButtonBuilder.new, r, &block
        self.controller.render_to_string partial: '/tabulatr/tabulatr_buttons', locals: {buttons: bb}, formats: [:html]
      }
      opts = {filter: false, sortable: false}.merge(opts)
      @columns << Buttons.from(klass: klass, col_options: Tabulatr::ParamsBuilder.new(opts), output: output, &block)
    end

    def filter(name, partial: nil, &block)
      if table_data
        found_filter = fetch_filter_from_table_data(name)
        @filters << found_filter if found_filter.present?
      else
        @filters << Tabulatr::Renderer::Filter.new(name, partial: partial, &block)
      end
    end

    def self.process(klass, table_data_object = nil, &block)
      i = self.new(klass, table_data_object)
      yield(i)
      i
    end

    private

    def fetch_column_from_table_data table_name, name, opts={}, &block
      column = table_data.table_columns.find{|tc| tc.table_name == table_name && tc.name == name}
      column.col_options.update(opts)
      column.output = block if block_given?
      column
    end

    def fetch_filter_from_table_data name
      table_data.filters.find{|f| f.name.to_sym == name.to_sym}
    end
  end
end
