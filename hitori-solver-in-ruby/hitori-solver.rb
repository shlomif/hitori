class HitoriSolver
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
    end

    DIR_X = 0
    DIR_Y = 1

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

        def cell_yx(y,x)
            return @cells[y][x]
        end

        def cell(dir, coords)
            if dir == 0 then
                return cell_yx(coords[0], coords[1])
            else
                return cell_yx(coords[1], coords[0])
            end
        end

        def row_max(dir)
            if (dir == DIR_X) then
                return maxx()
            else
                return maxy()
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

        def coords_loop
            for y in (0 .. maxy()) do
                for x in (0 .. maxx()) do
                    yield [y,x]
                end
            end
        end

        def loop_over_whites
            coords_loop do |yx|
                if cell_yx(*yx).state == Cell::WHITE then
                    yield yx
                end
            end
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

        def _find_regions()
            @board.loop_over_whites do |yx|
                found_regions = []
                for offset_yx in [[-1,0],[0,-1]] do
                    new_yx = [yx[0]+offset_yx[0], yx[1]+offset_yx[1]]
                    if (! @board.in_bounds(*new_yx)) then
                        next
                    end
                    if @board.cell_yx(*new_yx).state != Cell::WHITE then
                        next
                    end
                    found_regions << @cells_map[new_yx]
                end
                new_yx = nil
                
                add_to_region = lambda {|r|
                    @cells_map[yx] = r
                    @regions[r][yx] = true
                }
                if found_regions.length == 0 then
                    @cells_map[yx] = @regions.length
                    @regions << { yx => true }
                elsif found_regions.length == 1 then
                    add_to_region.call(found_regions[0])
                else

                    # found two regions - let's merge.
                    r_min = found_regions.min
                    r_max = found_regions.max

                    if (r_min == r_max) then
                        add_to_region.call(r_min)
                    else
                        @regions[r_max].each_key do |yx_temp|
                            @cells_map[yx_temp] = r_min
                        end
                        @regions[r_min].merge!(
                            @regions[r_max]
                        )
                        # Mark as consumed by r_min.
                        @regions[r_max] = r_min
                        add_to_region.call(r_min)
                    end
                end
            end
        end

        def _optimize_regions()
            new_regions = @regions.find_all { |r| r.class == Hash }
            new_regions.each_with_index do |members,i| 
                members.each_key { |yx| @cells_map[yx] = i }
            end
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

        class Counter < Hash
            def set_dir_val(dir, yx, val)
                coords = (dir == DIR_X) ? yx : yx.reverse
                row = coords[0]
                col = coords[1]
                myseqs = self[dir][row][val] ||= []
                    
                if (myseqs.length == 0) then
                    myseqs <<= [col]
                elsif (myseqs[-1][-1]+1 == col) then
                    myseqs[-1] << col
                else
                    myseqs << [col]
                end
            end

            def set_val(yx, val)
                for dir in [ DIR_X, DIR_Y ] do
                    set_dir_val(dir, yx, val)
                end
            end
        end

        def calc_sequences_counter()
            counter = Counter.new()

            counter[DIR_X] = (0 .. @board.maxx).map { |x| Hash.new }
            counter[DIR_Y] = (0 .. @board.maxy).map { |y| Hash.new }

            @board.coords_loop do |yx|
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

                if (sorted_seqs[1].length() >= 2) then
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

            for dir in [ DIR_X, DIR_Y ] do
                counter[dir].each_index do |row_idx| 
                    row = counter[dir][row_idx]
                    row.each do |val, seqs|
                        analyze_seqs_row(dir, row_idx, row, val, seqs)
                    end
                end
            end
        end

        def expand_white_regions()

        end

        def apply_a_single_move()
            while (@moves.length() > 0) do
                if _apply_move(@moves.shift()) then
                    return true
                end
            end
            return false
        end

        Offsets = [[-1,0],[0,-1],[0,1],[1,0]]

        def _apply_black_move(move)
            yx = [move.y, move.x]
            if !@board.cell_yx(*yx).mark_as_black() then
                return false
            end
            for offset_yx in Offsets do
                new_yx = [yx[0]+offset_yx[0], yx[1]+offset_yx[1]]
                if @board.in_bounds(*new_yx) then
                    add_move(
                        DIR_X, new_yx[0], new_yx[1],
                        "white",
                        "Neighboring cells to a black one should be white"
                    )
                end
            end
            return true
        end

        def _apply_white_move(move)
            yx = [move.y, move.x]
            if (!@board.cell_yx(*yx).mark_as_white())
                return false
            end
            val = @board.cell_yx(*yx).value
            # Look for identical values in the same x/y
            # and mark them as black.
            for dir in [ DIR_X, DIR_Y ] do
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
