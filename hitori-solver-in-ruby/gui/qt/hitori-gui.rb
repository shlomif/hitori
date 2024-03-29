#!/usr/bin/env ruby

# Copyright (c) 2010 Shlomi Fish
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# ----------------------------------------------------------------------------
#
# This is the MIT/X11 Licence. For more information see:
#
# 1. http://www.opensource.org/licenses/mit-license.php
#
# 2. http://en.wikipedia.org/wiki/MIT_License

# This code is adapted from ruby/qtruby/examples/tutorial/t14/ in the qtruby
# distribution.
#
# As of this writing, it still has a lot of leftover code from the original
# program, but we're working on eliminating it.

$VERBOSE = true; $:.unshift File.dirname($0)

$board_filename = ARGV.shift

require 'Qt'

class HitoriField < Qt::Widget
    def initialize(parent, hitori)
        super(parent)
        @hitori = hitori
        setPalette( Qt::Palette.new( Qt::Color.new( 250, 250, 200) ) )
        setAutoFillBackground(true)
    end

    Cell_Width = 30
    Cell_Height = 30

    def paintEvent( e )
        painter = Qt::Painter.new( self )

        painter.pen = Qt::Color.new(Qt::black)
        painter.font = Qt::Font.new( 'Courier', 15, Qt::Font::Bold )

        grey_color = Qt::Color.new(204,204,204)

        board = @hitori.board
        for y in (0 .. board.maxy) do
            for x in (0 .. board.maxx) do
                cell = board.cell_yx([y,x])
                s = cell.state
                val = cell.value

                painter.brush = \
                    (s == HitoriSolver::Cell::UNKNOWN) \
                    ? Qt::Brush.new(grey_color) \
                    : (s == HitoriSolver::Cell::BLACK) \
                    ? Qt::Brush.new(Qt::black) \
                    : Qt::Brush.new(Qt::white)

                square_rect = Qt::Rect.new(
                    x*Cell_Width,
                    y*Cell_Height,
                    Cell_Width,
                    Cell_Height
                )

                painter.drawRect(square_rect)

                painter.pen = \
                    (s == HitoriSolver::Cell::BLACK) \
                    ? grey_color \
                    : Qt::Color.new(Qt::black)

                painter.drawText(square_rect, Qt::AlignCenter, val.to_s())
            end
        end

        painter.end
    end
end

class GameBoard < Qt::Widget

    slots 'perform_op(QListWidgetItem *)', 'dump_board()'

    attr_reader :hitori

    def initialize(hitori)
        super()
        quit = Qt::PushButton.new('&Quit')
        quit.font = Qt::Font.new('Times', 18, Qt::Font::Bold)

        connect(quit, SIGNAL('clicked()'), $qApp, SLOT('quit()'))

        dump_button = Qt::PushButton.new('&Dump state')
        dump_button.font = Qt::Font.new('Times', 18, Qt::Font::Bold)
        connect(dump_button, SIGNAL('clicked()'), self, SLOT('dump_board()'))

        hitoriBox = Qt::Frame.new
        hitoriBox.frameStyle = Qt::Frame::WinPanel | Qt::Frame::Sunken

        @hitori = hitori

        @hitoriField = HitoriField.new(self, hitori)

        Qt::Shortcut.new(Qt::KeySequence.new(Qt::CTRL + Qt::Key_Q), self, SLOT('close()'))

        topLayout = Qt::HBoxLayout.new
        topLayout.addStretch(1)

        ops_list = Qt::ListWidget.new
        ops_list.addItem("analyze_sequences")
        ops_list.addItem("expand_white_regions")
        ops_list.addItem("analyze_single_value_L_shaped_corners")
        ops_list.addItem("analyze_xyx_triads")
        ops_list.addItem("apply_a_single_move")

        connect(ops_list, SIGNAL('itemClicked(QListWidgetItem *)'), \
                self, SLOT('perform_op(QListWidgetItem *)'))

        performed_moves_list = Qt::ListWidget.new

        bottomLayout = Qt::HBoxLayout.new()
        bottomLayout.addWidget( ops_list )
        bottomLayout.addWidget( performed_moves_list )

        @performed_moves_list = performed_moves_list

        hitoriLayout = Qt::VBoxLayout.new
        hitoriLayout.addWidget(@hitoriField)
        hitoriBox.layout = hitoriLayout

        bottomFrame = Qt::Frame.new
        bottomFrame.layout = bottomLayout

        mainSplitter = Qt::Splitter.new
        mainSplitter.setOrientation(Qt::Vertical)
        mainSplitter.addWidget(hitoriBox)
        mainSplitter.addWidget(bottomFrame)

        buttonLayout = Qt::HBoxLayout.new
        buttonLayout.addWidget(quit)
        buttonLayout.addWidget(dump_button)

        gridLayout = Qt::GridLayout.new
        gridLayout.addLayout( buttonLayout, 0, 0 )
        gridLayout.addLayout(topLayout, 0, 1)
        gridLayout.addWidget( mainSplitter, 1, 0, 1, 2 )
        gridLayout.setColumnStretch( 1, 10 )
        gridLayout.setRowMinimumHeight( 1, 200 )
		setLayout(gridLayout)

    end

    def dump_board()
        @hitori.dump_state_to_file("dump.rb");
    end

    def perform_op(item)
        method = item.text()
        @hitori.process.send(method)
        @hitoriField.repaint()

        @performed_moves_list.clear()
        @performed_moves_list.addItems(
            @hitori.process.format_moves()
        )
    end
end

require 'hitori-solver.rb'

class HitoriSolver::Process
    def format_moves()
        return self.performed_moves.map { |m| "(#{m.y},#{m.x}) = #{m.color} - #{m.reason}" }
    end
end

module HitoriSolver
    class Cell
        def status_as_string()
            return \
                ((state == HitoriSolver::Cell::WHITE) \
                 ? "HitoriSolver::Cell::WHITE" \
                 : "HitoriSolver::Cell::BLACK" \
                )
        end

        def as_string()
            if @state == HitoriSolver::Cell::UNKNOWN then
                return @value
            else
                return "[#{@value},#{status_as_string()}]"
            end
        end
    end
end

class MyHitoriGame
    attr_reader :board, :process

    def get_board()
        contents = [
            [2,1,3,2,4],
            [4,5,3,2,2],
            [3,4,2,5,1],
            [1,4,3,3,2],
            [2,5,1,4,3]
        ]

        if ($board_filename)
            return HitoriSolver::Board.parse(File.read($board_filename))
        else
            return [5,5,contents]
        end
    end

    def initialize()

        @board = HitoriSolver::Board.new(*get_board())
        @process = HitoriSolver::Process.new(@board)
    end

    def dump_state_to_file(filename)
        b = @board

        File.open(filename, "w") do |out|
            out.print("[\n");
            for y in (0 .. b.maxy) do
                out.print("    [");
                for x in (0 .. b.maxx) do
                     out.print(@board.cell_yx([y, x]).as_string(), ",")
                end
                out.print("],\n");
            end
            out.print("]\n");
        end
    end
end

app = Qt::Application.new(ARGV)

board = GameBoard.new(MyHitoriGame.new())
board.setGeometry( 100, 100, 500, 355 )
board.show
app.exec
