[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 10
  ny = 10
  xmin = -50
  ymin = -50
  xmax = 50
  ymax = 50
  uniform_refine = 3
[]

[Variables]
  [./phi]
  [../]
  [./u]
  [../]
[]

[AuxVariables]
  [./free_energy]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./solid]
  [../]
[]

[ICs]
  [./phiIC]
    type = SmoothCircleIC
    variable = phi
    block = 0
    x1 = 0
    y1 = 0
    radius = 2
    int_width = 0.5
    outvalue = -1
    invalue = 1
  [../]
  [./uIC]
    type = ConstantIC
    variable = u
    value = -0.05
  [../]
[]

[Kernels]
  [./w_dot]
    type = TimeDerivative
    variable = phi
  [../]
  [./anisoACinterface1]
    type = ACInterfaceKobayashi1
    variable = phi
    mob_name = M
  [../]
  [./anisoACinterface2]
    type = ACInterfaceKobayashi2
    variable = phi
    mob_name = M
  [../]
  [./AllenCahn]
    type = AllenCahn
    variable = phi
    mob_name = M
    f_name = fbulk
    args = u
  [../]
  [./T_dot]
    type = TimeDerivative
    variable = u
  [../]
  [./CoefDiffusion]
    type = Diffusion
    variable = u
  [../]
  [./w_dot_T]
    type = CoefCoupledTimeDerivative
    variable = u
    v = phi
    coef = -0.5
  [../]
[]

[AuxKernels]
  [./energy]
    type = TotalFreeEnergy
    variable = free_energy
    execute_on = 'initial timestep_end'
    f_name = fbulk
  [../]
  [./solidkernel]
    type = ParsedAux
    variable = solid
    function = 0.5*phi+0.5
    args = phi
  [../]
[]

[Materials]
  [./free_energy]
    type = DerivativeParsedMaterial
    block = 0
    f_name = fbulk
    args = 'phi u'
    constant_names = 'lambda'
    constant_expressions = '15.957'
    function = '-0.5*phi^2+0.25*phi^4+lambda*u*phi*(1-2/3*phi^2+0.2*phi^4)'
    derivative_order = 2
    outputs = exodus
  [../]
  [./material]
    type = InterfaceOrientationMaterial
    block = 0
    op = phi
    eps_bar = 1.0
    anisotropy_strength = 0.025
    mode_number = 4
    reference_angle = 0
    mob_name = M
    diffusion_coeff = 1
    outputs = exodus
  [../]
[]

[BCs]
  [./u_bc]
    type = DirichletBC
    variable = u
    value = -0.05
    boundary = '0 1 2 3'
  [../]
[]

[Postprocessors]
  [./total_energy]
    type = ElementIntegralVariablePostprocessor
    variable = free_energy
  [../]
  [./num_nodes]
    type = NumNodes
  [../]
  [./area]
    type = ElementIntegralVariablePostprocessor
    variable = solid
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  scheme = bdf2
  solve_type = PJFNK
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre    boomeramg      31'

  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-08
  l_max_its = 30

  end_time = 10000

  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 6
    iteration_window = 2
    dt = 0.001
    growth_factor = 1.25
    cutback_factor = 0.5
  [../]
  [./Adaptivity]
    initial_adaptivity = 2 # Number of times mesh is adapted to initial condition
    refine_fraction = 0.7 # Fraction of high error that will be refined
    coarsen_fraction = 0.1 # Fraction of low error that will coarsened
    max_h_level = 5 # Max number of refinements used, starting from initial mesh (before uniform refinement)
    weight_names = 'phi u'
    weight_values = '1 0.5'
  [../]
[]

[Outputs]
  interval = 2
  exodus = true
  csv = true
  file_base = prob1a_L100
[]
