import xlsxwriter 
import numpy as np

class Book(object):
    def add_sheet(self, sheet_name):
        sheet = self.workbook.add_worksheet(sheet_name)
        self.sheets[sheet_name] = Sheet(self, sheet)
        return self.sheets[sheet_name]

    def save(self):
        self.workbook.close()

    def _add_formats(self):
        self.percentage_format = self.workbook.add_format({'num_format': '0.00%'})
        self.title_format = self.workbook.add_format({'bold': True, 'align': 'center', 'font_size': 20, 'valign': 'center'})
        self.default_format = self.workbook.add_format({})

        self._section_format_a = self.workbook.add_format({'bold': True, 'align': 'center', 'bg_color': '#e8e9d8', 'border_color': 'white', 'border': 3}) # gray yellowD
        self._section_format_b = self.workbook.add_format({'bold': True, 'align': 'center', 'bg_color': '#ffcbc4', 'border_color': 'white', 'border': 3}) # peach 
        self._section_switch = True 

    def next_section_format(self):
        self._section_switch = not self._section_switch 
        return self._section_format_a if self._section_switch else self._section_format_b

    def get_section_format(self):
        return self._section_format_a if self._section_switch else self._section_format_b

    def __init__(self, filename):
        self.workbook = xlsxwriter.Workbook(filename + '.xlsx', {'nan_inf_to_errors': True})
        self.sheets = {}
        self._add_formats()

class Sheet(object):
    """book is the parent object of this sheet, sheet is the workbook sheet object this 
    class wraps. """
    def __init__(self, book, sheet):
        self.sheet = sheet
        self.book = book 
         
        self.top = 0 #record how far down into the workbook previous rows have impugned 
        self.new_top = 0 #rocord how far down the current row has ensorceled
        self.left  = 0 #record how far right into the notebook the current row has enpopulated

        self.section_title = ""


    """add a new section to the current sheet and write the styling for 
    the current section. """
    def new_section(self, section_name=None):
        if section_name is None:
            section_name = ""

        if self.section_title: #only do the colors if the section has a title
            self.sheet.write(self.top, 0, self.section_title, self.book.get_section_format())
            for row in range(self.top+1, self.new_top+1):
                self.sheet.write(row, 0, " ", self.book.get_section_format())
        
        self.top = self.new_top + 2
        self.section_title = section_name
        if section_name:
            self.left = 1
            self.book.next_section_format()
        else:
            self.left = 0


    """generate headers that say "Algorithm", "ds1", ..., "ds9", "{total_name}" with the passed format"""
    def _get_headers(self, format, total_name):
        column_headers = [{'header': f'ds{ds}', 'format': format} for ds in range(1, 10)]
        column_headers = [{'header': 'Algorithm'}] + column_headers + [{'header': total_name, 'format': format}]
        return column_headers

    """extract the specific passed stat from the summary dict and format the results in a way that 
    the xlsxwriter package can use to make a table. """
    def _stat_to_table(self, summary, stat_name):
        return [[meta] + [sum[stat_name] for sum in sums] for (meta, sums) in summary.items() if sums]

    """Using the passed summary stat dict and specific summary stat, create a table of the results with the 
    passed title. Tables are inserted next in line in the same row. """
    def add_summary_table(self, summary, stat_name, table_title, column_headers=None, last_col_total=False):
        #get the array of arrays format xlsxwriter will need later
        table = self._stat_to_table(summary, stat_name)

        #add the total column or percentage column at the end of the table
        if last_col_total:
            for row in table:
                row.append(sum(row[1:]))
        else:
            for row in table:
                weights = [90 - sum["invalid"] for sum in summary[row[0]] if sum ]
                row.append(np.average(row[1:], weights=weights))

        #determine the width and height of this data 
        width = len(table[0]) - 1
        height = len(table)

        #create the table title
        self.sheet.merge_range(self.top, self.left, self.top, 
            self.left + width, table_title, self.book.get_section_format())

        #if headers are passed, use those, otherwise use the defaults
        if column_headers is None:
            if last_col_total:
                column_headers = self._get_headers(self.book.default_format, "Total")
            else:
                column_headers = self._get_headers(self.book.percentage_format, "Weighted Average")

        #create the table
        self.sheet.add_table(
            self.top+1, self.left,
            self.top + height+1, self.left + width,
            {'data': table, 
                'columns': column_headers})
        
        #leave a gap between this table and the next one
        self.left += width + 2

        #if this table was higher than the previous tallest thing we added to the 
        #current section, we need to update the new_top variable
        self.new_top = max(self.top + height + 1, self.new_top)

    def add_big_title(self, title, width):
        #create the table title
        self.sheet.merge_range(self.top, self.left, self.top + 1, 
            self.left + width, title, self.book.title_format)
        self.left += width 
        self.new_top = max(self.new_top, self.top + 1)

    def add_image(self, filepath):
        pass