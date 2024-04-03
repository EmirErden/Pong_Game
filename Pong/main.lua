-- https://github.com/Ulydev/push
push = require 'push'

-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

--Paddle class
require 'Paddle'

--Ball class
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200


function love.load()
    --useful for pixelated graphics
    love.graphics.setDefaultFilter('nearest', 'nearest')

    --set the title of the game
    love.window.setTitle('Pong')

    --uses the current time give random number
    math.randomseed(os.time())

    --creating new fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    --set up sound effect table
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    --scores of the players
    player1Score = 0
    player2Score = 0

    --either will be 1 or 2 in the beginning the is no winner
    servingPlayer = 1

    --initializing our player paddles
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    --initializing the ball
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    --setting the gameState
    gameState = 'start'
end

function love.resize(w, h)
    push:resize(w, h)       
end

function love.update(dt)
    if gameState == 'serve' then
        --initialize ball's velocity according to player who scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then 
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        --detect ball colision and reverst speed
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            --keep velocity in the same direction but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)    
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            --keep velocity in the same direction but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)    
            end

            sounds['paddle_hit']:play()
        end

        --detect upper and lower screen boundary collision
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        --4 to account for ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end
    end

    --incremanting the scores of the players
    if ball.x < 0 then
        servingPlayer = 1
        player2Score = player2Score + 1
        sounds['score']:play()

        --if we've reached a score of 10 the game is over set the gameState to done
        if player2Score == 10 then
            winningPlayer = 2
            gameState = 'done'
        else
            gameState = 'serve'
            --resets the ball
            ball:reset()
        end
    end

    if ball.x > VIRTUAL_WIDTH then
        servingPlayer = 2
        player1Score = player1Score + 1
        sounds['score']:play()

        if player1Score == 10 then
            winningPlayer = 1
            gameState = 'done'
        else
            gameState = 'serve'
            ball:reset()
        end
    end

    --PLAYER1 Movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    --PLAYER2 Movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED   
    else
        player2.dy = 0 
    end

    --update our ball when gamestate is play
    if gameState == 'play' then
        ball:update(dt)
    end

    --calling update function of the player objects
    player1:update(dt)
    player2:update(dt)
    
end

--function for when a key is pressed it will do something
function love.keypressed(key)
    --when esc pressed game will close
    if key == 'escape' then
        love.event.quit()

    --when enter or return pressed game will enter the play state    
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            --game is simply restarting
            gameState = 'serve'

            ball:reset()

            --reset scores to 0
            player1Score = 0
            player2Score = 0

            --decide serving player
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1    
            end
        end
    end
end

function love.draw()
    --start rendering
    push:apply('start')

    --this will change the background color
    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    --this will write the Hello pong text
    love.graphics.setFont(smallFont)

    displayScore()

    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')  
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player '.. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')    
    elseif gameState == 'play' then
        --no UI message   
    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    --render paddles
    player1:render()
    player2:render()

    --render ball
    ball:render()

    --function for displaying the FPS
    displayFPS()

    --end rendering
    push:apply('end')
end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    
end

function displayScore()
    --draw score on the left and right side of the screen
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
end 
