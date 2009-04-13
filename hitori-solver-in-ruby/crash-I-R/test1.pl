use strict;
use warnings;

use Inline 'Ruby';

my $hitori = MyHitoriGame->new();

my $process = $hitori->get_process();
my $board = $hitori->get_board();

$process->analyze_sequences();

while (1)
{
    $process->apply_a_single_move();
    foreach my $y (0 .. 4)
    {
        foreach my $x (0 .. 4)
        {
            print "[", $board->cell_yx($y,$x)->state(), "]";
        }
        print "\n";
    }
    print "\n";
}

__END__
__Ruby__

require 'hitori-solver.rb'

class HitoriSolver::Process
    def format_moves()
        return self.performed_moves.map { |m| "(#{m.y},#{m.x}) = #{m.color} - #{m.reason}" }
    end
end

class MyHitoriGame
    def initialize()
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
    def get_board()
        return @board
    end

    def get_process()
        return @process
    end
end
