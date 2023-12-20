--Start of Global Scope---------------------------------------------------------

--------------------------------------------------------------------------------------
-- Parameters
local compensationMethod = 'rotate'   -- Rotate and translate the profiles according to the background. Note that the
                                      -- samples are not necessarily ordered with increasing X-coordinate after the
                                      -- rotation. This can cause problems for some funktions.

--local compensationMethod = 'subtract' -- Subtract the background model from the profiles.Note that this means that
                                        -- value-axis is not necessarily orthogonal to the X-axis any more. Thus, the
                                        -- values is not the orthogonal distance to the background.

local polyOrder = 1   -- Order of polynomial to fit. If compensationMethod == 'rotate' the order must be 1

local sleepTime = 10  -- Sleep between profiles in ms

--------------------------------------------------------------------------------------
-- Creating viewers to display the results
local v1 = View.create('v1')
v1:clear()
local v2 = View.create('v2')
v2:clear()

local gDeco = View.GraphDecoration.create():setXBounds(0, 90):setYBounds(-5, 35)
local gDecoOrig = View.GraphDecoration.create()
gDecoOrig:setXBounds(0, 90):setTitle("No compensation"):setYBounds(-5, 35)

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- Fit a polynomial to the profile
local CF = Profile.CurveFitter.create()

---@param profile Profile
---@param polyOrder float
---@param startIndexes table
---@param stopIndexes table
---@param compensationMethod string
---@return Profile backgroundModel
local function fitModel(profile, polyOrder, startIndexes, stopIndexes, compensationMethod)

  -- Create profile with the samples on the background.
  -- Alternatively specify region to not include in the fitting and use Profile.setValidFlagRange()
  local profileFitt = Profile.crop(profile, startIndexes[1], stopIndexes[1])
  for k = 2, #startIndexes do
    Profile.concatenateInplace(profileFitt, Profile.crop(profile, startIndexes[k], stopIndexes[k]))
  end

  local backgroundPoly = Profile.CurveFitter.fitPolynomial(CF, profileFitt, polyOrder)

  -- Select model to compensate with
  local backgroundModel
  if compensationMethod == "rotate" then
    backgroundModel = backgroundPoly
  elseif compensationMethod == "subtract" then
    backgroundModel = Profile.Curve.toProfile(backgroundPoly, profile)
  else
    print("Method must be 'rotate' or 'subtract'")
  end

  return backgroundModel
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

---Compensate the profile with the model
---@param profile Profile
---@param backgroundModel Profile
---@param method string
---@return Profile compensated
local function compensateStatic(profile, backgroundModel, method)
  local compensated

  if method == "rotate" then
    local polyCoeff = backgroundModel:getPolynomialParameters()
    if #polyCoeff ~= 2 then
      print("Background model must be a line.")
      return nil
    end

    local rotateAng = -math.tan(polyCoeff[2])
    compensated = Profile.rotate(profile, rotateAng, 0.0, polyCoeff[1])
    compensated:translateInplace(0.0, -polyCoeff[1])
  elseif method == "subtract" then
    compensated = Profile.subtract(profile, backgroundModel)
  else
    print("Not yet implemented.")
    return nil
  end

  return compensated
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

---Make an adaptive compensation
---@param profile Profile
---@param startIndexes table
---@param stopIndexes table
---@param polyOrder float
---@param method string
---@return Profile profileCompensated
local function compensateAdaptive(profile, startIndexes, stopIndexes, polyOrder, method)
  local backgroundModel = fitModel(profile, polyOrder, startIndexes, stopIndexes, method)
  local profileCompensated = compensateStatic(profile, backgroundModel, method)

  return profileCompensated
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local function main()

  local hM = Object.load('resources/heightMap.json')

  -- Different compensations
  local staticOrAdaptiveV = {'static', 'adaptive'}

  -----------------------------------------------------
  -- Select region on background to fit model to
  local startIndexes = {0}
  local stopIndexes = {48*5}

  -- Test the different compensations
  for _,staticOrAdaptive in ipairs(staticOrAdaptiveV) do
    if staticOrAdaptive == "static" then
      gDeco:setTitle("Static compensation")
      -----------------------------------------------------
      -- Fit line to background in first profile
      local profile = Image.extractRowProfile(hM, 0)
      profile:convertCoordinateType("EXPLICIT_1D")
      local backgroundModel = fitModel(profile, polyOrder, startIndexes, stopIndexes, compensationMethod)

      ----------------------------------------------------
      -- Compensate
      -- Loop over the rows in the heightmap
      for k = 1, Image.getHeight(hM) do
        local profileLive = Image.extractRowProfile(hM, k-1)
        profileLive:convertCoordinateType("EXPLICIT_1D")
        local profileCompensated = compensateStatic(profileLive, backgroundModel, compensationMethod)

        v1:clear()
        v1:addProfile(profileLive, gDecoOrig)
        v1:present("ASSURED")
        v2:clear()
        v2:addProfile(profileCompensated, gDeco)
        v2:present("ASSURED")
        Script.sleep(sleepTime)
      end
    elseif staticOrAdaptive == "adaptive" then
      gDeco:setTitle("Adaptive compensation")
      -- Loop over the rows in the heightmap
      for k = 1, Image.getHeight(hM) do
        local profileLive = Image.extractRowProfile(hM, k-1)
        profileLive:convertCoordinateType("EXPLICIT_1D")
        local profileCompensated = compensateAdaptive(profileLive, startIndexes, stopIndexes, polyOrder, compensationMethod)

        v1:clear()
        v1:addProfile(profileLive, gDecoOrig)
        v1:present("ASSURED")
        v2:clear()
        v2:addProfile(profileCompensated, gDeco)
        v2:present("ASSURED")
        Script.sleep(sleepTime)
      end
    end
  end

  print("App finished")
end

Script.register('Engine.OnStarted', main)
-- serve API in global scope
