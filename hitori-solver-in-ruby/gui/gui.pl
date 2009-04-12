#!/usr/bin/perl

use strict;
use warnings;

package HitoriCanvas;

use Wx ':everything';
use Wx::Event qw(EVT_PAINT);

use base 'Wx::Window';

my $cell_width = 30;
my $cell_height = 30;

sub slurp
{
    my $filename = shift;
    {
        local $/;
        open my $in, "<", $filename;
        my $text = <$in>;
        close($in);
        return $text;
    }
}

sub assign_board_and_process
{
    my $self = shift;
    my $board = shift;
    my $process = shift;

    $self->{board} = $board;
    $self->{process} = $process;

    return;
}

sub new
{
    my $class = shift;
    my $parent = shift;

    my $self = $class->SUPER::new(
        $parent,
        wxID_ANY(),
        Wx::Point->new(20, 20),
        Wx::Size->new($cell_width*9, $cell_height*9)
    );

    EVT_PAINT( $self, \&OnPaint );

    return $self;
}

my $UNKNOWN = 0;
my $WHITE = 1;
my $BLACK = 2;

sub OnPaint
{
    my $self = shift;

    my $dc = Wx::PaintDC->new($self);

    my $black_pen = Wx::Pen->new(Wx::Colour->new(0,0,0), 4, wxSOLID());

    $dc->SetPen( $black_pen );

    $dc->SetTextForeground( Wx::Colour->new(0, 0, 255) );

    my $board = $self->{board};

    for my $y (0 .. $board->y_len()-1)
    {
        for my $x (0 .. $board->x_len()-1)
        {
            my $cell = $board->cell_yx($y,$x);
            my $status = $cell->state();
            my $val = $cell->value();

            if ($status eq $UNKNOWN)
            {
                $dc->SetBrush(wxGREY_BRUSH());
            }
            elsif ($status eq $WHITE)
            {
                $dc->SetBrush(wxWHITE_BRUSH());
            }
            elsif ($status eq $BLACK)
            {
                $dc->SetBrush(wxBLACK_BRUSH());
            }

            my $p_x = $cell_width*$x;
            my $p_y = $cell_height*$y;
            $dc->DrawRectangle(
                $p_x, $p_y, $cell_width, $cell_height
            );

            my $c_x = $p_x + $cell_width/2;
            my $c_y = $p_y + $cell_height/2;

            my ($w, $h) = $dc->GetTextExtent($val);
            $dc->DrawText(
                $val,
                $c_x - $w/2,
                $c_y - $h/2,
            );
        }
    }
}

sub perform_solve
{
    my $self = shift;
    my $move = shift;

    my $method = $move;

    $self->{process}->$method();


    $self->OnPaint();

    return;
}

package HitoriApp;

use base 'Wx::App';
use Wx ':everything';
use Wx::Event qw(EVT_LISTBOX_DCLICK);

sub new
{
    my ($class, $board, $process) = @_;

    my $self = $class->SUPER::new();

    $self->assign_board_and_process($board, $process);

    return $self;
}

sub OnInit
{
    my( $self ) = @_;

    my $frame = Wx::Frame->new( undef, -1, 'wxPerl', wxDefaultPosition, [ 200, 100 ] );

    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL());

    $frame->SetSizer($sizer);

    $frame->{board} = HitoriCanvas->new($frame);
    $sizer->Add($frame->{board}, 1, wxALL(), 10);
    $frame->{list} = Wx::ListBox->new(
        $frame,
        -1,
        wxDefaultPosition(),
        wxDefaultSize(),
        [qw(
            analyze_sequences
            apply_a_single_move
        )]
    );
    $sizer->Add($frame->{list}, 1, wxALL(), 10);

    $frame->{performed_moves_list} = Wx::ListBox->new(
        $frame,
        -1,
        wxDefaultPosition(),
        wxDefaultSize(),
        []
    );

    $sizer->Add($frame->{performed_moves_list}, 1, wxALL(), 10);

    $frame->SetSize(Wx::Size->new(600,400));
    $frame->Show( 1 );

    $self->{frame} = $frame;

    EVT_LISTBOX_DCLICK($frame->{list}, wxID_ANY(), sub {
            my $list = shift;
            my $event = shift;

            my $sel = $event->GetSelection();
            my $string = $list->GetString($sel);
            $frame->{board}->perform_solve($string);

            $frame->{performed_moves_list}->Set(
                [ @{$self->{process}->format_moves()} ]
            );
        }
    );

    return 1;
}


sub assign_board_and_process
{
    my ($self, $board, $process) = @_;

    $self->{board} = $board;
    $self->{process} = $process;
    $self->{frame}->{board}->assign_board_and_process($board, $process);

    return;
}

package main;

use Inline 'Ruby';

my $hitori = MyHitoriGame->new();

HitoriApp->new($hitori->get_board(), $hitori->get_process())->MainLoop();

__END__
__Ruby__

require 'hitori-solver.rb'

class HitoriSolver::Process
    def format_moves()
        return self.performed_moves.map { |m| "(#{m.y},#{m.y}) <- #{m.color} - #{m.reason}" }
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
