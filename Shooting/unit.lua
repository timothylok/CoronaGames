require "class"
require "globals"
require "auxiliary"

-- START:unitConstructor
Unit = Class( )

-- Unit constructor
function Unit:new( group, imagesheet )
	
    -- Create a new sprite and add it to the group
    local spriteInstance = display.newSprite( imagesheet, spriteSequences.shipsSequence )
    spriteInstance.x = -50
    spriteInstance.y = -50
    group:insert( spriteInstance )
    self.spriteInstance = spriteInstance

    -- START:unitBulletsInit
    -- Initialize the bullet delay counter
    self.alive = true
    self.nextBullet = 0
    -- Store a pointer to this class in the sprite
    self.spriteInstance.object = self
    -- END:unitBulletsInit
end
-- END:unitConstructor

-- START:unitFunctions
-- Set the unit's position
function Unit:setPosition( x, y )
    self.spriteInstance.x = x
    self.spriteInstance.y = y
end

-- Move the unit in the y direction
function Unit:move( )
    self.y = self.y + self.vy
    
    self.spriteInstance.rotation = 0
    self.spriteInstance.y = self.y
    self.spriteInstance.x = self.x
    
    -- Update the shooting delay counter
    self.nextBullet = self.nextBullet - 1
    -- END:enemyShootUpdate
end

-- Check whether the unit is out of bounds
function Unit:toggleDelete( )
	-- START:toggleDeleteAlive
    if ( self.alive == false) then
        return true
	-- END:toggleDeleteAlive
    elseif (( self.y < -20 ) or ( self.y > 500 )) then
        return true
    end
    
    return false
end

-- Remove the unit
function Unit:removeMe( )
    self.spriteInstance:removeSelf( )
    self.spriteInstance = nil
end
-- END:unitFunctions

-- START:unitBullets
-- Returns true if the unit can shoot
function Unit:canShoot( )
    -- Check the bullet delay counter is back to 0
    if (self.nextBullet <= 0) then
        -- Reset the counter to the player's reload time
        --   (depending on the unit type)
        if self.type == TYPE_PLAYER then
            self.nextBullet = BULLET_RELOAD
        else
            self.nextBullet = ENEMY_BULLET_RELOAD
                + math.random( ENEMY_BULLET_RELOAD )
        end
        return true
    end
    return false
end
-- END:unitBullets

-- START:enemyCollision
-- Enemy collision listener function
function enemyCollision( self, event )
    -- Check the target object's type
    local other = event.other.object
    -- Only process the collision if the other object is alive
    if ( other.alive == true ) then
        -- Player bullets destroy the unit
        if ( other.type == TYPE_PLAYER_BULLET ) then
            other.alive = false
            self.object.alive = false
        end
    end
end
-- END:enemyCollision

-- START:enemyConstructor
Enemy = Class( Unit )

-- Enemy constructor
-- START:enemyConstructorPhysics
function Enemy:new( group, spriteSet )
-- END:enemyConstructorPhysics
    -- Set position and speed
    self.x = 10 + math.random( 300 )
    self.y = -10
    self.vy = 3
    self.spriteInstance.x = self.x
    self.spriteInstance.y = self.y
    
    -- Prepare the enemy sprite
    self.spriteInstance:setSequence( ENEMY_1 )
    
    -- START:enemyListener
	-- Set the unit type
    self.type = TYPE_ENEMY
    -- Add the unit's physics body
    physics.addBody( self.spriteInstance, physicsData:get( ENEMY_1 ) )    
    -- Add a collision listener to the unit
    local instance = self.spriteInstance
    instance.collision = enemyCollision
    instance:addEventListener( "collision", instance )
    -- END:enemyListener
end
-- END:enemyConstructor

-- START:playerCollision
-- Player collision listener function
function playerCollision( self, event )
    -- Get the target object's type
    local other = event.other.object
    
    -- Only react to collisions if the other unit is alive
    if ( other.alive == true ) then
    
        if ( other.type == TYPE_ENEMY ) then
            -- Enemy ships subtract a life
            other.alive = false
            lives = lives - 1
            
        elseif ( other.type == TYPE_ENEMY_BULLET ) then
            -- Enemy bullets subtract a life
            other.alive = false
            lives = lives - 1
        -- END:playerCollision

        -- START:powerupCollision
        elseif ( other.type == TYPE_POWERUP ) then
            -- Power-ups add a life or improve our health
            if ( other.subtype == POWERUP_HEALTH ) then
                self.object.health = self.object.health + 1
            else
                lives = lives + 1
            end
            other.alive = false
        -- END:powerupCollision
        -- START:playerCollision
        end
    end
end
-- END:playerCollision

-- START:playerConstructor
Player = Class( Unit )

-- Player constructor
-- START:playerConstructorPhysics
function Player:new( group, spriteSet )
-- END:playerConstructorPhysics
    self.spriteInstance.x = WIDTH / 2
    self.spriteInstance.y = 400
    self.x = self.spriteInstance.x
    self.y = self.spriteInstance.y

    -- Don't set a target coordinate when the game starts
    self.targetX = self.spriteInstance.x
    self.targetY = self.spriteInstance.y
    
    -- Display the player's ship
    self.spriteInstance:setSequence( PLAYER_CENTRE )
    
    -- START:playerListener
	-- Store the unit type
    self.type = TYPE_PLAYER
    self.health = 5
    -- Add the player unit's physics body and collision listener
    physics.addBody( self.spriteInstance, physicsData:get( PLAYER_CENTRE ) )
    local instance = self.spriteInstance
    instance.collision = playerCollision
    instance:addEventListener( "collision", instance )
    -- END:playerListener
end
-- END:playerConstructor

-- START:playerFunctions
-- Set the player's target coordinates
function Player:setTargetPosition( x, y )
    self.targetX = x
    self.targetY = y
end

-- Remove target coordinates from the player's ship
function Player:resetTargetPosition( )
    self.targetX = self.spriteInstance.x
    self.targetY = self.spriteInstance.y
end

-- START:playerMovement
-- Move the player
function Player:move( )
    -- Calculate the distance to the target
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local vx = math.max( math.min( PLAYER_MAXSPEED, dx / PLAYER_SPEED_COEFF ), -PLAYER_MAXSPEED )
    self.x = self.x + vx
    self.spriteInstance.x = self.x
    
    -- Steer the ship right or left if it's moving horizontally
    if ( self.targetX > self.spriteInstance.x + 15 ) then
        self.spriteInstance:setSequence( PLAYER_RIGHT )
    elseif ( self.targetX < self.spriteInstance.x - 15 ) then
        self.spriteInstance:setSequence( PLAYER_LEFT )
    else
        self.spriteInstance:setSequence( PLAYER_CENTRE )
    end
    
    -- START:playerShootUpdate
    -- Update shooting
    self.nextBullet = self.nextBullet - 1
    -- END:playerShootUpdate
end
-- END:playerMovement
