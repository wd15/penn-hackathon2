[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 10
  ny = 10
  nz = 10
  xmin = -150
  ymin = -150
  zmin = -150
  xmax = 150
  ymax = 150
  zmax = 150
  uniform_refine = 1
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[MeshModifiers]
  [./center]
    type = AddExtraNodeset
    coord = '0 0 0'
    new_boundary = center
  [../]
  [./right_pt]
    type = AddExtraNodeset
    coord = '150 0 0'
    new_boundary = right_pt
  [../]
  [./pt3]
    type = AddExtraNodeset
    coord = '0 0 150'
    new_boundary = pt3
  [../]
[]

[Variables]
  [./chem]
    scaling = 1e4
  [../]
  [./phi]
  [../]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./disp_z]
  [../]
[]

[AuxVariables]
  [./Cout]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./ScalarStress]
    family = MONOMIAL
    order = CONSTANT
  [../]
[]

[ICs]
  [./phi_IC]
    type = SmoothCircleIC
    x1 = 0
    y1 = 0
    radius = 99.78
    invalue = 1
    outvalue = 0
    variable = phi
    int_width = 30
  [../]
[]

[Kernels]
  [./TensorMechanics]
  [../]
  [./cres]
    type = SplitCHParsed
    variable = phi
    kappa_name = kappa
    w = chem
    f_name = f_total
  [../]
  [./wres]
    type = SplitCHWRes
    variable = chem
    mob_name = M
  [../]
  [./time]
    type = CoupledTimeDerivative
    variable = chem
    v = phi
  [../]
[]
[AuxKernels]
  [./C_out]
    type = RankFourAux
    index_i = 0
    index_j = 0
    index_k = 0
    index_l = 0
    rank_four_tensor = elasticity_tensor
    execute_on = 'initial LINEAR'
    variable = Cout
  [../]
  [./Scalar_stress]
    type = RankTwoScalarAux
    rank_two_tensor = stress
    scalar_type = VonMisesStress
    variable = ScalarStress
  [../]
[]

[Materials]
  [./kappa]
    type = ParsedMaterial
    f_name = kappa
    constant_names = 'length_scale JineV kappa'
    constant_expressions = '1e-9 1.6e-19 3e-9'
    function = 'kappa*length_scale/JineV'
    outputs = exodus
  [../]
  [./h0]
    type = ParsedMaterial
    f_name = h0
    constant_names = 'length_scale JineV h0'
    constant_expressions = '1e-9 1.6e-19 2.4e8'
    function = 'h0*length_scale^3/JineV'
    outputs = exodus
  [../]
  [./f0]
    type = DerivativeParsedMaterial
    f_name = f0
    material_property_names = h0
    function = 'h0*phi^2*(phi-1)^2'
    args = phi
    outputs = exodus
    derivative_order = 2
  [../]
  [./M]
    type = GenericConstantMaterial
    prop_names = M
    prop_values = 1
  [../]
  #Mechanics
  [./elasticity_tensorA]
    type = ComputeElasticityTensor
    C_ijkl = '1456.8 901.9 725.9 1803 508.1 2372.4 621 548 700.9'
    fill_method = symmetric9
    base_name = A
  [../]
  [./elasticity_tensorB]
    type = ComputeElasticityTensor
    C_ijkl = '1678.96 1104.7 911.259 1678.96 911.259 2995.92 773.95 773.95 1198.37'
    fill_method = symmetric9
    base_name = B
  [../]
  [./Avar_dependence]
    type = DerivativeParsedMaterial
    function = 'phi^3*(6*phi^2 - 15*phi + 10)'
    args = phi
    f_name = A_dep
    derivative_order = 2
  [../]
  [./Bvar_dependence]
    type = DerivativeParsedMaterial
    function = '1-phi^3*(6*phi^2 - 15*phi + 10)'
    args = phi
    f_name = B_dep
    derivative_order = 2
  [../]
  [./composte_elasticity_tensor]
    type = CompositeElasticityTensor
    args = phi
    tensors = 'A     B'
    weights = 'A_dep B_dep'
  [../]
  [./eigen_strain]
    type = ComputeEigenstrain
    eigen_base = '0.006 0.0214774 -0.0059921 0 0 0'
  [../]
  [./stress]
    type = ComputeLinearElasticStress
  [../]
  [./strain]
    type = ComputeSmallStrain
  [../]
  [./ElasticEnergy]
    type = ElasticEnergyMaterial
    args = phi
    outputs = exodus
    f_name = f_elastic
    derivative_order = 2
  [../]
  [./total_energy]
    type = DerivativeSumMaterial
    args = phi
    sum_materials = 'f_elastic f0'
    f_name = f_total
    outputs = exodus
    derivative_order = 2
  [../]
[]

[BCs]
  [./fixed_center]
    type = PresetBC
    variable = 'disp_x disp_y disp_z'
    value = 0.0
    boundary = 'center'
  [../]
  [./fixed_right_pt]
    type = PresetBC
    variable = 'disp_y'
    value = 0.0
    boundary = 'right_pt'
  [../]
  [./fixed_pt3]
    type = PresetBC
    variable = 'disp_z'
    value = 0.0
    boundary = 'pt3'
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    coupled_groups = 'phi,chem disp_x,disp_y,disp_z'
  [../]
[]

[Postprocessors]
  [./Volume]
    type = ElementIntegralVariablePostprocessor
    variable = phi
    execute_on = 'initial timestep_end'
  [../]
  [./dt]
    type = TimestepSize
    execute_on = 'initial timestep_end'
  [../]
[]

[Executioner]
  type = Transient
  scheme = 'BDF2'
  solve_type = 'NEWTON'
  petsc_options_iname = '-pc_type  -sub_pc_type -sub_pc_factor_shift_type -sub_pc_factor_shift_amount -pc_asm_overlap'
  petsc_options_value = 'asm       lu           NONZERO                   1e-10 1'

  l_max_its = 30
  l_tol = 1.0e-4

  nl_max_its = 50
  nl_rel_tol = 1.0e-10
  nl_abs_tol = 1.0e-10

  num_steps = 200

  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 6
    iteration_window = 2
    dt = 10.0
    growth_factor = 1.1
    cutback_factor = 0.75
  [../]
  [./Adaptivity]
    initial_adaptivity = 2 # Number of times mesh is adapted to initial condition
    refine_fraction = 0.7 # Fraction of high error that will be refined
    coarsen_fraction = 0.1 # Fraction of low error that will coarsened
    max_h_level = 3 # Max number of refinements used, starting from initial mesh (before uniform refinement)
    weight_names = 'phi disp_x disp_y disp_z chem'
    weight_values = '1 0 0 0 0'
  [../]
[]

[Outputs]
  csv = true
  exodus = true
[]
