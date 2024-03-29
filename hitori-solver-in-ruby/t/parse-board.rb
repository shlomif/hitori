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

require "hitori_solver.rb"

class Object
    def ok()
        self.should == true
    end
    def not_ok()
        self.should == false
    end
end

module HitoriSolver
    class Move
        # exp == expected.
        def is_yx_col(exp_yx,exp_color)
            y.should == exp_yx[0]
            x.should == exp_yx[1]
            color.should == exp_color
        end
    end
end

describe "construct_board" do
    it "board No. 1 should" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        contents = [
            [2,1,3,2,4],
            [4,5,3,2,2],
            [3,4,2,5,1],
            [1,4,3,3,2],
            [2,5,1,4,3]
        ]
        board = HitoriSolver::Board.new(5, 5, contents)
        board.cell_yx([0,0]).value.should == 2
        board.cell_yx([0,1]).value.should == 1
        board.cell_yx([0,2]).value.should == 3
        board.cell_yx([4,2]).value.should == 1
        board.cell(0, [0,1]).value.should == 1
        board.cell(1, [0,1]).value.should == 4
    end
    it "should throw an exception for invalid x_len" do
        board = 0
        lambda {
            board = HitoriSolver::Board.new(2, 4, [[3,2,1],[4,5,6,7]])
        }.should raise_error(HitoriSolver::WrongRowLenException)
    end

    it "should throw an exception for invalid height" do
        board = 0
        lambda {
            board = HitoriSolver::Board.new(2, 4, [[3,2,1,4],[4,5,6,7], [1,1,2,1]])
        }.should raise_error(HitoriSolver::WrongHeightException)
    end
end

describe "Process for Board No. 1" do

    before (:each) do
        contents = [
            [2,1,3,2,4],
            [4,5,3,2,2],
            [3,4,2,5,1],
            [1,4,3,3,2],
            [2,5,1,4,3]
        ]

        @board = HitoriSolver::Board.new(5, 5, contents)

        @process = HitoriSolver::Process.new(@board)
    end

    it "should mark 2,0 as black in Board No. 1 and perform more moves" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        process.analyze_sequences()

        process.moves.length().should == 1
        process.moves[0].is_yx_col([3,2],"black");

        process.apply_a_single_move()
        board.cell_yx([3,2]).state.should == HitoriSolver::Cell::BLACK

        process.moves.length().should == 4
        process.moves[0].is_yx_col([2,2],"white")
        process.moves[1].is_yx_col([3,1],"white")
        process.moves[2].is_yx_col([3,3],"white")
        process.moves[3].is_yx_col([4,2],"white");

        # (y,x) = 2,2 ; color = white
        process.apply_a_single_move()
        process.moves.length().should == 3

        board.cell_yx([2,2]).state.should == HitoriSolver::Cell::WHITE

        # (y,x) = 3,1 ; color = white
        process.apply_a_single_move()
        process.moves.length().should == 3

        board.cell_yx([3,1]).state.should == HitoriSolver::Cell::WHITE
        process.moves[0].is_yx_col([3,3],"white")
        process.moves[1].is_yx_col([4,2],"white")
        process.moves[2].is_yx_col([2,1],"black")
    end

    it "should not repeat moves" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        process.analyze_sequences()

        done_moves = Hash.new()
        next_move = 0

        get_move_key = lambda { |m| return [m.y,m.x].join(",") }

        while process.moves.length() > 0 do
            while next_move < process.performed_moves.length()
                key = get_move_key.call(process.performed_moves[next_move])
                done_moves.has_key?(key).should == false
                done_moves[key] = 1
                next_move += 1
            end
            process.apply_a_single_move()
        end
    end
end

describe "Intermediate Process for Board No. 1" do

    before (:each) do

        contents = [
            [[2,HitoriSolver::Cell::BLACK],[1,HitoriSolver::Cell::WHITE],3,2,4,],
            [[4,HitoriSolver::Cell::WHITE],[5,HitoriSolver::Cell::WHITE],3,2,2,],
            [[3,HitoriSolver::Cell::WHITE],[4,HitoriSolver::Cell::BLACK],[2,HitoriSolver::Cell::WHITE],5,1,],
            [1,[4,HitoriSolver::Cell::WHITE],[3,HitoriSolver::Cell::BLACK],[3,HitoriSolver::Cell::WHITE],2,],
            [[2,HitoriSolver::Cell::WHITE],[5,HitoriSolver::Cell::BLACK],[1,HitoriSolver::Cell::WHITE],4,3,],
        ]

        @board = HitoriSolver::Board.new(5, 5, contents)

        @process = HitoriSolver::Process.new(@board)
    end

    it "should be initialized with proper colors" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        board.cell_yx([0,0]).value.should == 2
        board.cell_yx([0,0]).state.should == HitoriSolver::Cell::BLACK

        board.cell_yx([0,1]).value.should == 1
        board.cell_yx([0,1]).state.should == HitoriSolver::Cell::WHITE

        board.cell_yx([1,0]).value.should == 4
        board.cell_yx([1,0]).state.should == HitoriSolver::Cell::WHITE

        board.cell_yx([1,2]).value.should == 3
        board.cell_yx([1,2]).state.should == HitoriSolver::Cell::UNKNOWN

    end

    it "white_regions should be OK." do
        regions_manager = HitoriSolver::WhiteRegions.new(@board)
        regions_manager.calc_regions()

        regions_manager.regions[0].whites.should == {
            [0,1] => true, [1,0] => true, [1,1] => true, [2,0] => true,
        };

        regions_manager.regions[0].adjacent_blacks.should == {
            [0,0] => true, [2,1] => true
        };

    end

    it "should analyze white-colored regions properly" do
        board = @board

        white_regions = HitoriSolver::WhiteRegions.new(board)
        white_regions.calc_regions()

        check_region = lambda { |yx, cells|
            region_id = white_regions.cells_map[yx]
            region = white_regions.regions[region_id]

            region.whites.should == cells.inject({}) {|h, v| h[v] = true; h }

            return;
        }

        verify_region = lambda { |cells|
            cells.each { |yx| check_region.call(yx, cells) }

            return;
        }

        verify_region.call([[4,0]])

        verify_region.call([[0,1], [1,0], [1,1], [2,0],])

        verify_region.call([[4,2]])

        verify_region.call([[3,1]])

        verify_region.call([[3,3]])

        verify_region.call([[2,2]])

        white_regions.cells_map.has_key?([0,0]).should == false

        white_regions.cells_map.has_key?([0,2]).should == false

    end

    it "should expand white-colored areas" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        process.expand_white_regions()

        process.moves.length.should == 3
        process.moves[0].is_yx_col([3,0],"white")
        process.moves[1].is_yx_col([3,0],"white")
        process.moves[2].is_yx_col([4,3],"white")
    end

end

describe "single-digit-L-corner test" do


    before (:each) do

        contents = [
            [[2,HitoriSolver::Cell::BLACK],[1,HitoriSolver::Cell::WHITE],3,2,4,],
            [[4,HitoriSolver::Cell::WHITE],[5,HitoriSolver::Cell::WHITE],3,2,2,],
            [[3,HitoriSolver::Cell::WHITE],[4,HitoriSolver::Cell::BLACK],[2,HitoriSolver::Cell::WHITE],5,1,],
            [[1,HitoriSolver::Cell::WHITE],[4,HitoriSolver::Cell::WHITE],[3,HitoriSolver::Cell::BLACK],[3,HitoriSolver::Cell::WHITE],2,],
            [[2,HitoriSolver::Cell::WHITE],[5,HitoriSolver::Cell::BLACK],[1,HitoriSolver::Cell::WHITE],[4,HitoriSolver::Cell::WHITE],3,],
]

        @board = HitoriSolver::Board.new(5, 5, contents)

        @process = HitoriSolver::Process.new(@board)
    end

    it "should process a single-digit L-shaped corner" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        process.analyze_single_value_L_shaped_corners()

        process.moves.length.should == 1
        process.moves[0].is_yx_col([1,3],"black")
    end

end

describe "parse the board" do

    before (:each) do

        @contents = [
            [[2,HitoriSolver::Cell::BLACK],[1,HitoriSolver::Cell::WHITE],3,2,4,],
            [[4,HitoriSolver::Cell::WHITE],[5,HitoriSolver::Cell::WHITE],3,2,2,],
            [[3,HitoriSolver::Cell::WHITE],[4,HitoriSolver::Cell::BLACK],[2,HitoriSolver::Cell::WHITE],5,1,],
            [[1,HitoriSolver::Cell::WHITE],[4,HitoriSolver::Cell::WHITE],[3,HitoriSolver::Cell::BLACK],[3,HitoriSolver::Cell::WHITE],2,],
            [[2,HitoriSolver::Cell::WHITE],[5,HitoriSolver::Cell::BLACK],[1,HitoriSolver::Cell::WHITE],[4,HitoriSolver::Cell::WHITE],3,],
]

    end

    it "should parse the string correctly" do

        got_contents = HitoriSolver::Board.parse(<<"EOF")
5*5
[2B] [1W] [3]  [2U] [4]
[4W] [5W] [3]  [2]  [2U]
[3W] [4B] [2W] [5]  [1]
[1W] [4W] [3B] [3W] [2]
[2W] [5B] [1W] [4W] [3U]
EOF

        got_contents.should == [5,5,@contents,]
    end

end

describe "Process for Board No. 2" do

    before (:each) do

        params = HitoriSolver::Board.parse(
            File.read("./boards/menneske.no-2.txt")
        )

        @board = HitoriSolver::Board.new(*params)

        @process = HitoriSolver::Process.new(@board)
    end

    it "should not die upon analyze_sequences" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        process.analyze_sequences()

        # Reached here successfully .
        1.should == 1
    end
end

describe "Process for En-Wikipedia Board" do

    before (:each) do

        contents = [
            [4,8,1,6,3,2,5,7,],
            [3,6,7,2,1,6,5,4,],
            [2,3,4,8,2,8,6,1,],
            [4,1,6,5,7,7,3,5,],
            [7,2,3,1,8,5,1,2,],
            [3,5,6,7,3,1,8,4,],
            [6,4,2,3,5,4,[7,HitoriSolver::Cell::WHITE],[8,HitoriSolver::Cell::WHITE],],
            [8,7,1,4,2,[3,HitoriSolver::Cell::WHITE],[5,HitoriSolver::Cell::BLACK],[6,HitoriSolver::Cell::WHITE],],
        ]

        @board = HitoriSolver::Board.new(8,8, contents)

        @process = HitoriSolver::Process.new(@board)
    end

    it "should analyze XYX triads properly" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        process.analyze_xyx_triads()
        process.moves[0].is_yx_col([2,4],"white")

    end
end
