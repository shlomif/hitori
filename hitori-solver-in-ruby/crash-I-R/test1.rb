require "hitori-solver.rb"

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

while 1 do
    process.apply_a_single_move()
    (0..4).each { |y| 
        (0..4).each { |x| print "[#{board.cell_yx(y,x).state}]" }
        print "\n"
    }
    print "\n"
end

