require "hitori-solver.rb"

class Object
    def ok()
        self.should == true
    end
    def not_ok()
        self.should == false
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
        board.cell_yx(0,0).value.should == 2
        board.cell_yx(0,1).value.should == 1
        board.cell_yx(0,2).value.should == 3
        board.cell_yx(4,2).value.should == 1
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
        process.moves[0].y.should == 3
        process.moves[0].x.should == 2
        process.moves[0].color.should == "black"

        process.apply_a_single_move()
        board.cell_yx(3,2).state.should == HitoriSolver::Cell::BLACK

        process.moves.length().should == 4
        process.moves[0].y.should == 2
        process.moves[0].x.should == 2
        process.moves[0].color.should == "white"
        process.moves[1].y.should == 3
        process.moves[1].x.should == 1
        process.moves[1].color.should == "white"
        process.moves[2].y.should == 3
        process.moves[2].x.should == 3
        process.moves[2].color.should == "white"
        process.moves[3].y.should == 4
        process.moves[3].x.should == 2
        process.moves[3].color.should == "white"

        # (y,x) = 2,2 ; color = white
        process.apply_a_single_move()
        process.moves.length().should == 3

        board.cell_yx(2,2).state.should == HitoriSolver::Cell::WHITE

        # (y,x) = 3,1 ; color = white
        process.apply_a_single_move()
        process.moves.length().should == 3

        board.cell_yx(3,1).state.should == HitoriSolver::Cell::WHITE
        process.moves[0].y.should == 3
        process.moves[0].x.should == 3
        process.moves[0].color.should == "white"
        process.moves[1].y.should == 4
        process.moves[1].x.should == 2
        process.moves[1].color.should == "white"
        process.moves[2].y.should == 2
        process.moves[2].x.should == 1
        process.moves[2].color.should == "black"
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

        board.cell_yx(0,0).value.should == 2
        board.cell_yx(0,0).state.should == HitoriSolver::Cell::BLACK 

        board.cell_yx(0,1).value.should == 1
        board.cell_yx(0,1).state.should == HitoriSolver::Cell::WHITE

        board.cell_yx(1,0).value.should == 4
        board.cell_yx(1,0).state.should == HitoriSolver::Cell::WHITE

        board.cell_yx(1,2).value.should == 3
        board.cell_yx(1,2).state.should == HitoriSolver::Cell::UNKNOWN

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
    end

    it "should expand white-colored areas" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        #
        board = @board
        process = @process

        process.expand_white_regions()

        # process.moves[0].y.should == 3
        # process.moves[0].x.should == 0
        # process.moves[0].color.should == "white"

    end

end
