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

    class Cell
        $UNKNOWN = 0
        $WHITE = 1
        $BLACK = 2

        attr_reader :state
        attr_reader :value

        def initialize(val)
            @state = $UNKNOWN
            @value = val
        end

        def mark_as_white()
            @state = $WHITE
        end

        def mark_as_black()
            @state = $BLACK
        end
    end

    $DIR_X = 0
    $DIR_Y = 1

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

        def maxx()
            return @x_len-1
        end

        def maxy()
            return @y_len-1
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

    class Process
        attr_reader :moves
        def initialize(board)
            @board = board
            @moves = Array.new
        end

        def get_move(dir, row, column, color, reason)
            coords = (dir == $DIR_X) ? [row, column] : [column, row]
            coords.push(color, reason)
            return Move.new(*coords)
        end

        class Counter < Hash
            def set_dir_val(dir, yx, val)
                coords = (dir == $DIR_X) ? yx : yx.reverse
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
                for dir in [ $DIR_X, $DIR_Y ] do
                    set_dir_val(dir, yx, val)
                end
            end
        end


        def calc_sequences_counter()
            counter = Counter.new()
            counter[$DIR_X] = (0 .. @board.maxx).map { |x| Hash.new }
            counter[$DIR_Y] = (0 .. @board.maxy).map { |y| Hash.new }
            for x in (0 .. @board.maxx) do
                for y in (0 .. @board.maxy) do
                    yx = [y,x]
                    val = @board.cell(0, yx).value

                    counter.set_val(yx, val)
                end
            end
            return counter
        end

        def analyze_sequences()
            counter = self.calc_sequences_counter()

            for dir in [ $DIR_X, $DIR_Y ] do
                counter[dir].each_index do |row_idx| 
                    row = counter[dir][row_idx]
                    row.each do |val, seqs|
                        sorted_seqs = \
                            seqs.sort { |a,b| -(a.length() <=> b.length()) }
                        if (sorted_seqs[0].length() >= 4) then
                            raise FourInARowException, \
                                "Found four in a row in #{dir} #{row}"
                        elsif (sorted_seqs[0].length() == 3) then
                            if (sorted_seqs[1].length() >= 2) then
                                raise TwoPairsException, \
                                    "Found two pairs in #{dir} #{row}"
                            else
                                @moves.push(
                                    self.get_move(
                                        dir, row_idx, sorted_seqs[0][1],
                                        "white",
                                        "Three in a row"
                                    )
                                )
                            end
                        elsif (sorted_seqs[0].length() == 2) then
                            if (sorted_seqs.length > 1) then
                                if (sorted_seqs[1].length() == 2) then
                                    raise TwoPairsException, \
                                    "Found two pairs in #{dir} #{row}"
                                end
                                sorted_seqs[1..-1].each do |seq|
                                    @moves.push(
                                        self.get_move(
                                            dir, row_idx, seq[0],
                                            "black",
                                            "An adjacent pair and some standalones mark the standalones as black"
                                        )
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
