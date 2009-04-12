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
    end
end
