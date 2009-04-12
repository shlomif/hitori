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

    it "should mark 2,0 as black in Board No. 1" do
        # http://www.menneske.no/hitori/5x5/eng/showpuzzle.html?number=1
        contents = [
            [2,1,3,2,4],
            [4,5,3,2,2],
            [3,4,2,5,1],
            [1,4,3,3,2],
            [2,5,1,4,3]
        ]
        board = HitoriSolver::Board.new(5, 5, contents)
        process = HitoriSolver::Process.new(board)
        process.analyze_sequences()
        process.moves.length().should == 1
        process.moves[0].x.should == 2
        process.moves[0].y.should == 3
        process.moves[0].color.should == "black"
    end
end
