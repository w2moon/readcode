local texture = "fx/torchfire.tex"
local shader = "shaders/particle.ksh"
local colour_envelope_name = "firecolourenvelope"
local scale_envelope_name = "firescaleenvelope"

local assets =
{
	Asset( "IMAGE", texture ),
	Asset( "SHADER", shader ),
}

local max_scale = 3

local function IntColour( r, g, b, a )
	return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelope()
	if EnvelopeManager and not init then
		init = true
		EnvelopeManager:AddColourEnvelope(
			colour_envelope_name,
			{	{ 0,	IntColour( 187, 187, 215, 30 ) },
				{ 0.49,	IntColour( 187, 187, 215, 30 ) },
				{ 0.5,	IntColour( 255, 255, 255, 30 ) },
				{ 0.51,	IntColour( 255, 230, 245, 30 ) },
				{ 0.75,	IntColour( 255, 225, 250, 30 ) },
				{ 1,	IntColour( 255, 200, 206, 0 ) },
			} )

		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{
				{ 0,	{ max_scale * 0.5, max_scale } },
				{ 1,	{ max_scale * 0.5 * 0.5, max_scale * 0.5 } },
			} )
	end
end

local max_lifetime = 0.3
--local ground_height = 0.1

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    -- inst.entity:AddLight()
    inst.entity:AddNetwork()

	InitEnvelope()

    local emitter = inst.entity:AddParticleEmitter()
	emitter:SetRenderResources(texture, shader)
	emitter:SetMaxNumParticles(64)
	emitter:SetMaxLifetime(max_lifetime)
	emitter:SetColourEnvelope(colour_envelope_name)
	emitter:SetScaleEnvelope(scale_envelope_name)
	emitter:SetBlendMode(BLENDMODE.Additive)
	emitter:EnableBloomPass(true)
	emitter:SetUVFrameSize(0.25, 1)
    emitter:SetSortOrder(1)

	-----------------------------------------------------
	local tick_time = TheSim:GetTickTime()

	local desired_particles_per_second = 64
	local particles_per_tick = desired_particles_per_second * tick_time

	local num_particles_to_emit = 1

	local sphere_emitter = CreateSphereEmitter(0.05)

	local function emit_fn()
		local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
		local lifetime = max_lifetime * (0.9 + UnitRand() * 0.1)
		local px, py, pz

		px, py, pz = sphere_emitter()
		px = px + (.25 - (math.random()*.5))
		py = py + .4 + (.25 - (math.random()*.5))

		local uv_offset = math.random(0, 3) * 0.25

		emitter:AddParticleUV(
			lifetime,			-- lifetime
			px, py, pz,			-- position
			vx, vy, vz,			-- velocity
			uv_offset, 0		-- uv offset
		)
	end
	
	local function updateFunc()
		while num_particles_to_emit > 1 do
			emit_fn(emitter)
			num_particles_to_emit = num_particles_to_emit - 1
		end

		num_particles_to_emit = num_particles_to_emit + particles_per_tick
	end

	EmitterManager:AddEmitter(inst, nil, updateFunc)

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddTag("FX")
    inst.persists = false

    -- inst.Light:Enable(true)
    -- inst.Light:SetIntensity(.75)
    -- inst.Light:SetColour(197 / 255, 197 / 255, 197 / 255)
    -- inst.Light:SetFalloff(0.5)
    -- inst.Light:SetRadius(2)

    return inst
end

return Prefab("hauntfx", fn, assets)