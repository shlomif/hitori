#!/usr/bin/env ruby

# This code is adapted from ruby/qtruby/examples/tutorial/t14/ in the qtruby
# distribution.
#
# As of this writing, it still has a lot of leftover code from the original
# program, but we're working on eliminating it.

$VERBOSE = true; $:.unshift File.dirname($0)

require 'Qt'

include Math

class CannonField < Qt::Widget

    slots  'newTarget()', 'setGameOver()', 'restartGame()'

    def initialize(parent, hitori)
        super(parent)
        @hitori = hitori
        @shootAngle = 0
        @shootForce = 0
        @target = Qt::Point.new(0, 0)
        @gameEnded = false
        @barrelPressed = false
        setPalette( Qt::Palette.new( Qt::Color.new( 250, 250, 200) ) )
        setAutoFillBackground(true)
        newTarget()
        @barrelRect = Qt::Rect.new(30, -5, 20, 10)
    end

    def gameOver() 
        return @gameEnded 
    end


    @@first_time = true
    
    def newTarget()
        if @@first_time
            @@first_time = false
            midnight = Qt::Time.new( 0, 0, 0 )
            srand( midnight.secsTo(Qt::Time.currentTime()) )
        end
        @target = Qt::Point.new( 200 + rand(190), 10  + rand(255) )
        update()
    end
    
    def mousePressEvent( e )
        if e.button() != Qt::LeftButton
            return
        end
    end

    def mouseMoveEvent( e )
        if !@barrelPressed
            return
        end
        pnt = e.pos();
        if pnt.x() <= 0
            pnt.setX( 1 )
        end
        if pnt.y() >= height()
            pnt.setY( height() - 1 )
        end
        rad = atan2((rect().bottom()-pnt.y()), pnt.x())
    end

    def mouseReleaseEvent( e )
        if e.button() == Qt::LeftButton
            @barrelPressed = false
        end
    end

    Cell_Width = 30
    Cell_Height = 30

    def paintEvent( e )
        painter = Qt::Painter.new( self )

        painter.pen = Qt::Color.new(Qt::black)
        painter.font = Qt::Font.new( 'Courier', 15, Qt::Font::Bold )

        grey_color = Qt::Color.new(204,204,204)

        board = @hitori.board
        for y in (0 .. board.maxy) do
            for x in (0 .. board.maxx) do
                cell = board.cell_yx(y,x)
                s = cell.state
                val = cell.value

                painter.brush = \
                    (s == HitoriSolver::Cell::UNKNOWN) \
                    ? Qt::Brush.new(grey_color) \
                    : (s == HitoriSolver::Cell::BLACK) \
                    ? Qt::Brush.new(Qt::black) \
                    : Qt::Brush.new(Qt::white)

                square_rect = Qt::Rect.new(
                    x*Cell_Width,
                    y*Cell_Height, 
                    Cell_Width, 
                    Cell_Height 
                )
                
                painter.drawRect(square_rect) 

                painter.pen = \
                    (s == HitoriSolver::Cell::BLACK) \
                    ? grey_color \
                    : Qt::Color.new(Qt::black)

                painter.drawText(square_rect, Qt::AlignCenter, val.to_s())
            end
        end
        
        painter.end
    end

    def shotRect()
        gravity = 4.0

        velocity  = @shootForce
        radians   = @shootAngle*3.14159265/180.0

        velx      = velocity*cos( radians )
        vely      = velocity*sin( radians )
        x0        = ( @barrelRect.right()  + 5.0 )*cos(radians)
        y0        = ( @barrelRect.right()  + 5.0 )*sin(radians)
        x         = x0 + velx*time
        y         = y0 + vely*time - 0.5*gravity*time*time

        r = Qt::Rect.new( 0, 0, 6, 6 );
        r.moveCenter( Qt::Point.new( x.round, height() - 1 - y.round ) )
        return r
    end

    def targetRect()
        r = Qt::Rect.new( 0, 0, 20, 10 )
        r.moveCenter( Qt::Point.new(@target.x(),height() - 1 - @target.y()) )
        return r
    end
end

class GameBoard < Qt::Widget

    slots 'perform_op(QListWidgetItem *)', 'newGame()'

    attr_reader :hitori

    def initialize(hitori)
        super()
        quit = Qt::PushButton.new('&Quit')
        quit.font = Qt::Font.new('Times', 18, Qt::Font::Bold)
    
        connect(quit, SIGNAL('clicked()'), $qApp, SLOT('quit()'))
    
        cannonBox = Qt::Frame.new
        cannonBox.frameStyle = Qt::Frame::WinPanel | Qt::Frame::Sunken

        @hitori = hitori

        @cannonField = CannonField.new(self, hitori)

        shoot = Qt::PushButton.new( '&Shoot' )
        shoot.font = Qt::Font.new( 'Times', 18, Qt::Font::Bold )

        restart = Qt::PushButton.new( '&New Game' )
        restart.font = Qt::Font.new( 'Times', 18, Qt::Font::Bold )

        connect( restart, SIGNAL('clicked()'), self, SLOT('newGame()') )

        @hits = Qt::LCDNumber.new( 2, self )
        @shotsLeft = Qt::LCDNumber.new( 2, self  )
        hitsLabel = Qt::Label.new( 'HITS', self  )
        shotsLeftLabel = Qt::Label.new( 'SHOTS LEFT', self  )
                
        Qt::Shortcut.new(Qt::KeySequence.new(Qt::CTRL + Qt::Key_Q), self, SLOT('close()'))
                                     
        topLayout = Qt::HBoxLayout.new
        topLayout.addWidget(shoot)
        topLayout.addWidget(@hits)
        topLayout.addWidget(hitsLabel)
        topLayout.addWidget(@shotsLeft)
        topLayout.addWidget(shotsLeftLabel)
        topLayout.addStretch(1)
        topLayout.addWidget(restart)

        ops_list = Qt::ListWidget.new
        ops_list.addItem("analyze_sequences")
        ops_list.addItem("apply_a_single_move")

        connect(ops_list, SIGNAL('itemDoubleClicked(QListWidgetItem *)'), \
                self, SLOT('perform_op(QListWidgetItem *)'))

        performed_moves_list = Qt::ListWidget.new

        leftLayout = Qt::VBoxLayout.new()
        leftLayout.addWidget( ops_list )
        leftLayout.addWidget( performed_moves_list )

        @performed_moves_list = performed_moves_list

        cannonLayout = Qt::VBoxLayout.new
        cannonLayout.addWidget(@cannonField)
        cannonBox.layout = cannonLayout

        gridLayout = Qt::GridLayout.new
        gridLayout.addWidget( quit, 0, 0 )
        gridLayout.addLayout(topLayout, 0, 1)
        gridLayout.addLayout(leftLayout, 1, 0)
        gridLayout.addWidget( cannonBox, 1, 1, 2, 1 )
        gridLayout.setColumnStretch( 1, 10 )
		setLayout(gridLayout)
    
    end
    
    def perform_op(item)
        method = item.text()
        @hitori.process.send(method)
        @cannonField.repaint()
    end
end

require 'hitori-solver.rb'

class HitoriSolver::Process
    def format_moves()
        return self.performed_moves.map { |m| "(#{m.y},#{m.x}) = #{m.color} - #{m.reason}" }
    end
end

class MyHitoriGame
    attr_reader :board, :process
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
end

app = Qt::Application.new(ARGV)

board = GameBoard.new(MyHitoriGame.new())
board.setGeometry( 100, 100, 500, 355 )
board.show
app.exec
