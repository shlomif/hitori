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

module HitoriSolver
    class WrongRowLenException < RuntimeError
    end
    class WrongHeightException < RuntimeError
    end
    class UnsolvableException < RuntimeError
    end
    class FourInARowException < UnsolvableException
    end
    class TwoPairsException < UnsolvableException
    end
    class CellShouldBeDifferentColor < UnsolvableException
    end
    class ParseException < RuntimeError
    end
    class DimsParseException < ParseException
    end

    class Cell
        UNKNOWN = 0
        WHITE = 1
        BLACK = 2

        attr_reader :state
        attr_reader :value

        def initialize(val)
            @state = UNKNOWN
            if (val.class == Array) then
                @value = val[0]
                @state = val[1]
            else
                @value = val
            end
        end

        # If the existing state is unknown, marks the cell as the new color
        # and returns true. (So it's a performed move)
        #
        # If the existing state is the right color, then return false, because
        # we're not performing a new move.
        #
        # If we try to convert the cell into a new color, then raise an
        # unsolvable exception.
        def _mark_as(new_state)
            if (@state == UNKNOWN)
                @state = new_state
                return true
            elsif (@state == new_state)
                return false
            else
                raise CellShouldBeDifferentColor
            end
        end

        def mark_as_white()
            return _mark_as(WHITE)
        end

        def mark_as_black()
            return _mark_as(BLACK)
        end

        def is_white()
            return @state == WHITE
        end

        def is_black()
            return @state == BLACK
        end
 
        def is_unknown()
            return @state == UNKNOWN
        end
        
    end

    DIR_X = 0
    DIR_Y = 1

    DIRS = [DIR_X, DIR_Y]

    class Board
        attr_reader :x_len
        attr_reader :y_len

        def initialize(height, width, contents) 
            @x_len = width
            @y_len = height
            board = []
            for s_row in contents do
                d_row = []
                for v in s_row do
                    d_row << Cell.new(v)
                end
                if (d_row.length() != @x_len)
                    raise WrongRowLenException, \
                        "Wrong number of values in row #{board.length()}."
                end
                board << d_row
            end
            if (board.length() != @y_len)
                raise WrongHeightException, "There aren't #{@y_len} rows";
            end
            @cells = board
        end

        def cell_yx(yx)
            y, x = yx
            return @cells[y][x]
        end

        def cell(dir, coords)
            if dir == DIR_X then
                return cell_yx(coords)
            else
                return cell_yx(coords.reverse)
            end
        end

        def row_max(dir)
            if (dir == DIR_X) then
                return maxx()
            else
                return maxy()
            end
        end

        def col_max(dir)
            if (dir == DIR_X) then
                return maxy()
            else
                return maxx()
            end
        end


        def in_bounds(y,x)
            return (   (0 <= y) && (y < @y_len) \
                    && (0 <= x) && (x < @x_len)
                   )
        end

        def maxx()
            return @x_len-1
        end

        def maxy()
            return @y_len-1
        end

        class Coords_Loop
            include Enumerable

            def initialize(maxy, maxx) 
                @maxy = maxy
                @maxx = maxx
            end

            def each
                ( 0 .. @maxy ).each do |y|
                    ( 0 .. @maxx ).each do |x|
                        yield [y,x]
                    end
                end
            end
        end

        def all_coords
            return Coords_Loop.new(maxy(), maxx())
        end

        def all_whites
            return all_coords.select { |yx| cell_yx(yx).is_white() }
        end

        def self.parse(board_string)
            lines = board_string.split(/\n/)
            next_line = 0
            dims = lines[next_line]
            next_line += 1
            if dims =~ /^(\d+)\*(\d+)\s*\z/ then
                height, width = $1.to_i, $2.to_i
            else
                raise DimsParseException, "Could not parse dimensions at line 1";
            end

            contents = []
            for y in 1 .. height do
                line = lines[next_line]
                next_line += 1
                out_line = []
                for x in 0 .. (width-1) do
                    if line.sub!(/^\[(\d+)(W|B|U|)\]\s*/, "")
                        id, status = $1.to_i(), $2
                        if (status == "U" or status == "")
                            out_line << id
                        else
                            out_line << [id, 
                                (status == "W" ? 
                                 HitoriSolver::Cell::WHITE :
                                 HitoriSolver::Cell::BLACK)]
                        end
                    else
                        raise CellParseException, "Could not parse cell at line #{next_line}";
                    end
                end
                contents << out_line
            end

            return [height, width, contents]
        end

        def _get_offsets(with_next)
            if with_next
                return [[-1,0],[0,-1],[0,1],[1,0]]
            else
                return [[-1,0],[0,-1]]
            end
        end

        def neighbors(init_yx, with_next = true)
            _get_offsets(with_next).map { |offset_yx| 
                [init_yx[0]+offset_yx[0], init_yx[1]+offset_yx[1]]
            }.select { |new_yx| in_bounds(*new_yx) }
        end

    end

    class Move
        attr_reader :y, :x, :color, :reason
        def initialize(y,x,color, reason)
            @y = y
            @x = x
            @color = color
            @reason = reason
        end
    end

    class WhiteRegions
 

        attr_reader :regions, :cells_map

        def initialize(board)
            @board = board
            @regions = []
            @cells_map = {}
        end

        class Region

            attr_reader :whites, :adjacent_blacks, :regions
            def initialize()
                @whites = {}
                @adjacent_blacks = {}
                @adjacent_unknowns = {}
            end

            def add_white(yx)
                @whites[yx] = true
            end

            def white_coords
                return @whites.keys
            end

            def merge!(other_region)
                @whites.merge!(other_region.whites())
                # TODO : add blacks and greys
            end

            def _calc_adjacent(board)
                board.all_coords.each do |yx|
                    # TODO : Write better. The loop with assignment 
                    # is ugly.
                    is_adj = false
                    board.neighbors(yx).each do |adj_yx|
                        if (whites.has_key?(adj_yx)) then
                            is_adj = true
                        end
                    end
                    if (! is_adj) then
                        next
                    end
                    if board.cell_yx(yx).is_black() then
                        @adjacent_blacks[yx] = true
                    elsif board.cell_yx(yx).is_unknown() then
                        @adjacent_unknowns[yx] = true
                    end
                end
            end

            def get_adjacent_unknowns
                return @adjacent_unknowns.keys
            end
        end

        def _find_adjacent_regions(yx)
            found_regions = []
            @board.neighbors(yx, false).each do |new_yx|
                if ! @board.cell_yx(new_yx).is_white() then
                    next
                end
                found_regions << @cells_map[new_yx]
            end
            return found_regions
        end

        def _find_regions_for_coords(yx)
            found_regions = _find_adjacent_regions(yx)

            add_to_region = lambda {|r|
                @cells_map[yx] = r
                @regions[r].add_white(yx)
            }
            if found_regions.length == 0 then
                @cells_map[yx] = @regions.length
                new_r = Region.new
                new_r.add_white(yx)
                @regions << new_r
            elsif found_regions.length == 1 then
                add_to_region.call(found_regions[0])
            else

                # found two regions - let's merge.
                r_min = found_regions.min
                r_max = found_regions.max

                if (r_min == r_max) then
                    add_to_region.call(r_min)
                else
                    @regions[r_max].white_coords.each do |yx_temp|
                        @cells_map[yx_temp] = r_min
                    end
                    @regions[r_min].merge!(@regions[r_max])
                    # Mark as consumed by r_min.
                    @regions[r_max] = r_min
                    add_to_region.call(r_min)
                end
            end
        end

        def _find_regions()
            @board.all_whites.each do |yx|
                _find_regions_for_coords(yx)
            end
        end

        def _optimize_regions()
            new_regions = @regions.find_all { |r| r.class == Region }

            new_regions.each_with_index do |members,i| 
                members.white_coords.each { |yx| @cells_map[yx] = i }
            end

            new_regions.each { |r| r._calc_adjacent(@board) }

            @regions = new_regions
        end

        def calc_regions()
            _find_regions()
            _optimize_regions()
        end

    end

    class Process

        attr_reader :moves, :performed_moves
        def initialize(board)
            @board = board
            @moves = Array.new
            @performed_moves = Array.new
        end

        def get_move(dir, row, column, color, reason)
            coords = (dir == DIR_X) ? [row, column] : [column, row]
            coords.push(color, reason)
            return Move.new(*coords)
        end

        def add_move(dir, row, column, color, reason)
            @moves << get_move(dir, row, column, color, reason)
            return
        end

        def add_yx_move(yx, color, reason)
            add_move(DIR_X, yx[0], yx[1], color, reason)
        end

        class Counter < Hash
            def set_dir_val(dir, yx, val)
                coords = (dir == DIR_X) ? yx : yx.reverse
                row = coords[0]
                col = coords[1]
                myseqs = self[dir][row][val] ||= []
                    
                if (myseqs.length == 0) then
                    myseqs << [col]
                elsif (myseqs[-1][-1]+1 == col) then
                    myseqs[-1] << col
                else
                    myseqs << [col]
                end
            end

            def set_val(yx, val)
                DIRS.each do |dir|
                    set_dir_val(dir, yx, val)
                end
            end
        end

        def calc_sequences_counter()
            counter = Counter.new()

            counter[DIR_X] = (0 .. @board.maxx).map { |x| Hash.new }
            counter[DIR_Y] = (0 .. @board.maxy).map { |y| Hash.new }

            @board.all_coords.each do |yx|
                val = @board.cell(0, yx).value

                counter.set_val(yx, val)
            end

            return counter
        end

        def analyze_seqs_row(dir, row_idx, row, val, seqs)

            sorted_seqs = seqs.sort { |a,b| -(a.length() <=> b.length()) }

            if (sorted_seqs[0].length() >= 4) then

                raise FourInARowException, \
                    "Found four in a row in #{dir} #{row}"

            elsif (sorted_seqs[0].length() == 3) then

                if sorted_seqs.length > 1 and sorted_seqs[1].length() >= 2
                    raise TwoPairsException, \
                        "Found two pairs in #{dir} #{row}"
                else
                    add_move(
                        dir, row_idx, sorted_seqs[0][1],
                        "white",
                        "Three in a row"
                    )
                end

            elsif (sorted_seqs[0].length() == 2) then

                if (sorted_seqs.length > 1) then
                    if (sorted_seqs[1].length() == 2) then
                        raise TwoPairsException, \
                        "Found two pairs in #{dir} #{row}"
                    end
                    sorted_seqs[1..-1].each do |seq|
                        add_move(
                            dir, row_idx, seq[0],
                            "black",
                            "An adjacent pair and some standalones mark the standalones as black"
                        )
                    end
                end

            end
        end

        def analyze_sequences()
            counter = self.calc_sequences_counter()

            DIRS.each do |dir|
                counter[dir].each_with_index do |row, row_idx| 
                    row.each do |val, seqs|
                        analyze_seqs_row(dir, row_idx, row, val, seqs)
                    end
                end
            end
        end

        # This analyzes triads that look like 1-2-1 where if the 2 had been
        # black then both 1's would have been white and so it must be white.
        def analyze_xyx_triads()
            b = @board
            DIRS.each do |dir|
                ( 0 .. b.row_max(dir) ).each do |y|
                    ( 0 .. b.col_max(dir)-2 ).each do |x|
                        val = lambda { |x1| return b.cell(dir,[y,x1]).value }
                        if val.call(x) == val.call(x+2)
                            add_move(
                                dir, y, x+1, "white",
                                "The Y in an XYX triad sequence should be white"
                            )
                        end
                    end
                end
            end
        end

        def analyze_single_value_L_shaped_corners()

            dir = DIR_X

            v = lambda { |yx| return @board.cell(dir, yx).value };

            analyze_coords = lambda { |coords, two, three|
                val = v.call(coords)
                if ((val == v.call(two)) && (val == v.call(three)))
                    add_move(
                        dir, coords[0], coords[1], "black",
                        "Single-value L-shaped corner must be white-black-white"
                    )        
                end
            }

            row = @board.row_max(dir)
            col = @board.col_max(dir)

            for c in [[1,0],[col-1,col]] do
                for r in [[1,0], [row-1,row]] do
                    analyze_coords.call(
                        [c[0],r[0]],
                        [c[1],r[0]],
                        [c[0],r[1]]
                    )
                end
            end
        end

        def expand_white_regions()
            white_regions = WhiteRegions.new(@board)

            white_regions.calc_regions()

            white_regions.regions.each do |r|
                unknowns = r.get_adjacent_unknowns()
                if (unknowns.length == 1)
                    add_yx_move(
                        unknowns[0],
                        "white",
                        "Extending a white region to the only adjacent cell in an unknown state"
                   )
                end
            end
        end

        def apply_a_single_move()
            while (@moves.length() > 0) do
                if _apply_move(@moves.shift()) then
                    return true
                end
            end
            return false
        end


        def _apply_black_move(move)
            yx = [move.y, move.x]
            if !@board.cell_yx(yx).mark_as_black() then
                return false
            end
            @board.neighbors(yx).each do |new_yx|
                add_yx_move(
                    new_yx,
                    "white",
                    "Neighboring cells to a black one should be white"
                )
            end
            return true
        end

        def _apply_white_move(move)
            yx = [move.y, move.x]
            if (!@board.cell_yx(yx).mark_as_white())
                return false
            end
            val = @board.cell_yx(yx).value
            # Look for identical values in the same x/y
            # and mark them as black.
            DIRS.each do |dir|
                row = yx[dir]
                for col in (0 .. @board.row_max(dir)) do
                    if col != yx[1-dir] then
                        if (@board.cell(dir, [row,col]).value == val)
                            add_move(
                                dir, row, col,
                                "black",
                                ("A square in the same row/column as a " + 
                                "white square and with an identical value " +
                                "becomes black")
                            )
                        end
                    end
                end
            end
            return true
        end

        def _apply_move(move)
            ret = (move.color == "black") \
                ? _apply_black_move(move) \
                : _apply_white_move(move)
            if (ret)
                @performed_moves << move
            end
            return ret
        end
    end
end
