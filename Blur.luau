--blur made by bocaj111004
local effect = Instance.new("DepthOfFieldEffect", game:GetService("Lighting"))
effect.FarIntensity = 0
effect.FocusDistance = 51.6
effect.InFocusRadius = 50
effect.NearIntensity = 1
effect.Enabled = true
local Module = {}
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

do
	local function IsNotNaN(X)
		return X == X
	end
	local Continue = IsNotNaN(Camera:ScreenPointToRay(0,0).Origin.X)
	while not Continue do
		RunService.RenderStepped:Wait()
		Continue = IsNotNaN(Camera:ScreenPointToRay(0,0).Origin.X)
	end
end

local Binds = {}
local Root = Instance.new("Folder", Camera)
Root.Name = "Neon"

local GenUid do
	local Id = 0
	function GenUid()
		Id = Id + 1
		return "Neon::" .. tostring(Id)
	end
end

local DrawQuad do
	local Acos, Max, Pi, Sqrt = math.acos, math.max, math.pi, math.sqrt
	local Sz = 0.2

	function DrawTriangle(V1, V2, V3, P0, P1)
		local S1 = (V1 - V2).Magnitude
		local S2 = (V2 - V3).Magnitude
		local S3 = (V3 - V1).Magnitude
		local SMax = Max(S1, S2, S3)
		local A, B, C
		if S1 == SMax then
			A, B, C = V1, V2, V3
		elseif S2 == SMax then
			A, B, C = V2, V3, V1
		elseif S3 == SMax then
			A, B, C = V3, V1, V2
		end

		local Para = ((B-A).X*(C-A).X + (B-A).Y*(C-A).Y + (B-A).Z*(C-A).Z) / (A-B).Magnitude
		local Perp = Sqrt((C-A).Magnitude^2 - Para*Para)
		local DifPara = (A - B).Magnitude - Para

		local St = CFrame.new(B, A)
		local Za = CFrame.Angles(Pi/2,0,0)

		local Cf0 = St

		local TopLook = (Cf0 * Za).LookVector
		local MidPoint = A + CFrame.new(A, B).LookVector * Para
		local NeededLook = CFrame.new(MidPoint, C).LookVector
		local Dot = TopLook.X*NeededLook.X + TopLook.Y*NeededLook.Y + TopLook.Z*NeededLook.Z

		local Ac = CFrame.Angles(0, 0, Acos(Dot))

		Cf0 = Cf0 * Ac
		if ((Cf0 * Za).LookVector - NeededLook).Magnitude > 0.01 then
			Cf0 = Cf0 * CFrame.Angles(0, 0, -2*Acos(Dot))
		end
		Cf0 = Cf0 * CFrame.new(0, Perp/2, -(DifPara + Para/2))

		local Cf1 = St * Ac * CFrame.Angles(0, Pi, 0)
		if ((Cf1 * Za).LookVector - NeededLook).Magnitude > 0.01 then
			Cf1 = Cf1 * CFrame.Angles(0, 0, 2*Acos(Dot))
		end
		Cf1 = Cf1 * CFrame.new(0, Perp/2, DifPara/2)

		if not P0 then
			P0 = Instance.new("Part")
			P0.FormFactor = "Custom"
			P0.TopSurface = 0
			P0.BottomSurface = 0
			P0.Anchored = true
			P0.CanCollide = false
			P0.Material = "Glass"
			P0.Size = Vector3.new(Sz, Sz, Sz)
			local Mesh = Instance.new("SpecialMesh", P0)
			Mesh.MeshType = 2
			Mesh.Name = "WedgeMesh"
		end
		P0.WedgeMesh.Scale = Vector3.new(0, Perp/Sz, Para/Sz)
		P0.CFrame = Cf0

		if not P1 then
			P1 = P0:Clone()
		end
		P1.WedgeMesh.Scale = Vector3.new(0, Perp/Sz, DifPara/Sz)
		P1.CFrame = Cf1

		return P0, P1
	end

	function DrawQuad(V1, V2, V3, V4, Parts)
		Parts[1], Parts[2] = DrawTriangle(V1, V2, V3, Parts[1], Parts[2])
		Parts[3], Parts[4] = DrawTriangle(V3, V2, V4, Parts[3], Parts[4])
	end
end

function Module:BindFrame(Frame, Properties)
	if Binds[Frame] then
		return Binds[Frame].Parts
	end

	local Uid = GenUid()
	local Parts = {}
	local F = Instance.new("Folder", Root)
	F.Name = Frame.Name

	local Parents = {}
	do
		local function Add(Child)
			if Child and pcall(function() return Child:IsA("GuiObject") end) and Child:IsA("GuiObject") then
				Parents[#Parents + 1] = Child
				Add(Child.Parent)
			end
		end
		Add(Frame)
	end

	local function UpdateOrientation(FetchProps)
		if not Frame or not Frame.Parent then
			Module:UnbindFrame(Frame)
			return
		end
		local ZIndex = 1 - 0.05 * Frame.ZIndex
		local Tl, Br = Frame.AbsolutePosition, Frame.AbsolutePosition + Frame.AbsoluteSize
		local Tr, Bl = Vector2.new(Br.X, Tl.Y), Vector2.new(Tl.X, Br.Y)

		do
			local Rot = 0
			for _, V in ipairs(Parents) do
				Rot = Rot + V.Rotation
			end
			if Rot ~= 0 and Rot % 180 ~= 0 then
				local Mid = Tl:Lerp(Br, 0.5)
				local S, C = math.sin(math.rad(Rot)), math.cos(math.rad(Rot))
				local Vec = Tl
				Tl = Vector2.new(C*(Tl.X - Mid.X) - S*(Tl.Y - Mid.Y), S*(Tl.X - Mid.X) + C*(Tl.Y - Mid.Y)) + Mid
				Tr = Vector2.new(C*(Tr.X - Mid.X) - S*(Tr.Y - Mid.Y), S*(Tr.X - Mid.X) + C*(Tr.Y - Mid.Y)) + Mid
				Bl = Vector2.new(C*(Bl.X - Mid.X) - S*(Bl.Y - Mid.Y), S*(Bl.X - Mid.X) + C*(Bl.Y - Mid.Y)) + Mid
				Br = Vector2.new(C*(Br.X - Mid.X) - S*(Br.Y - Mid.Y), S*(Br.X - Mid.X) + C*(Br.Y - Mid.Y)) + Mid
			end
		end

		DrawQuad(
			Camera:ScreenPointToRay(Tl.X, Tl.Y, ZIndex).Origin,
			Camera:ScreenPointToRay(Tr.X, Tr.Y, ZIndex).Origin,
			Camera:ScreenPointToRay(Bl.X, Bl.Y, ZIndex).Origin,
			Camera:ScreenPointToRay(Br.X, Br.Y, ZIndex).Origin,
			Parts
		)

		if FetchProps then
			for _, Pt in pairs(Parts) do
				Pt.Parent = F
			end
			for PropName, PropValue in pairs(Properties) do
				for _, Pt in pairs(Parts) do
					Pt[PropName] = PropValue
				end
			end
		end
	end

	UpdateOrientation(true)
	RunService:BindToRenderStep(Uid, 2000, UpdateOrientation)

	Binds[Frame] = {
		Uid = Uid,
		Parts = Parts
	}
	return Binds[Frame].Parts
end

function Module:Modify(Frame, Properties)
	local Parts = Module:GetBoundParts(Frame)
	if Parts then
		for PropName, PropValue in pairs(Properties) do
			for _, Pt in pairs(Parts) do
				Pt[PropName] = PropValue
			end
		end
	else
		warn(("No part bindings exist for %s"):format(Frame:GetFullName()))
	end
end

function Module:UnbindFrame(Frame)
	local Cb = Binds[Frame]
	if Cb then
		RunService:UnbindFromRenderStep(Cb.Uid)
		for _, V in pairs(Cb.Parts) do
			V:Destroy()
		end
		Binds[Frame] = nil
	else
		warn(("No part bindings exist for %s"):format(Frame:GetFullName()))
	end
end

function Module:HasBinding(Frame)
	return Binds[Frame] ~= nil
end

function Module:GetBoundParts(Frame)
	return Binds[Frame] and Binds[Frame].Parts
end

return Module
