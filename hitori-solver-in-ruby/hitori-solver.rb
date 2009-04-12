class HitoriSolver
    class WrongRowLenException < RuntimeError
    end
    class WrongHeightException < RuntimeError
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

    class Process
        def initialize(board)
            @board = board
        end

        def solve()
            for x in (0 .. @board.maxx) do
                triads = Hash.new();
                for y in (0 .. @board.maxy) do

                    val = @board.cell_yx(y,x).value

                    triads[val] ||= \
                        { 'p' => [], 'is_pair' => false}

                    if (triads[val]['p'][-1] == y-1) then
                        triads[val]['is_pair'] = true;
                    end

                    triads[val]['p'] << y

                    if ((triads[val]['p'].length() >= 3) &&
                         triads[val]['is_pair']) then

                    end
                end
            end
        end
    end
end
