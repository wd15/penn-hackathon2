/****************************************************************/
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*          All contents are licensed under LGPL V2.1           */
/*             See LICENSE for full restrictions                */
/****************************************************************/

/* NOTE: This file was modified for the Phase Field Hackathon III
         problems. It is not meant for general use in the MOOSE
         framework. */

#include "InterfaceOrientationMaterial.h"
#include "MooseMesh.h"

template<>
InputParameters validParams<InterfaceOrientationMaterial>()
{
  InputParameters params = validParams<Material>();
  params.addParam<Real>("anisotropy_strength", 0.04, "Strength of the anisotropy (typically < 0.05)");
  params.addParam<unsigned int>("mode_number", 6, "Mode number for anisotropy");
  params.addParam<Real>("reference_angle", 90, "Reference angle for defining anistropy in degrees");
  params.addParam<Real>("eps_bar", 0.01, "Average value of the interface parameter epsilon");
  params.addParam<std::string>("mob_name", "L", "Base name of the mobility");
  params.addParam<Real>("diffusion_coeff", 1, "Thermal Diffusion Constant Coefficient");
  params.addRequiredCoupledVar("op", "Order parameter defining the solid phase");
  return params;
}

InterfaceOrientationMaterial::InterfaceOrientationMaterial(const InputParameters & parameters) :
    Material(parameters),
    _delta(getParam<Real>("anisotropy_strength")),
    _j(getParam<unsigned int>("mode_number")),
    _theta0(getParam<Real>("reference_angle")),
    _eps_bar(getParam<Real>("eps_bar")),
    _eps(declareProperty<Real>("eps")),
    _deps(declareProperty<Real>("deps")),
    _depsdgrad_op(declareProperty<RealGradient>("depsdgrad_op")),
    _ddepsdgrad_op(declareProperty<RealGradient>("ddepsdgrad_op")),
    _op(coupledValue("op")),
    _grad_op(coupledGradient("op")),
    _mob_name(getParam<std::string>("mob_name")),
    _prop_F(&declareProperty<Real>(_mob_name)),
    _tau0(getParam<Real>("diffusion_coeff"))
{
  // this currently only works in 2D simulations
  if (_mesh.dimension() != 2)
    mooseError("InterfaceOrientationMaterial requires a two-dimensional mesh.");
}

void
InterfaceOrientationMaterial::computeQpProperties()
{
  Real cutoff = 0.99999;

  // cosine of the gradient orientation angle
  Real n;
  if (_grad_op[_qp].norm() == 0)
    n = 0;
  else
    n = _grad_op[_qp](0) / _grad_op[_qp].norm();

  if (n > cutoff)
    n = cutoff;

  if (n < -cutoff)
    n = -cutoff;

  const Real angle = std::acos(n);

  // Compute derivative of angle wrt n
  const Real dangledn = - 1.0 / std::sqrt(1.0 - n * n);

  // Compute derivative of n with respect to grad_op
  RealGradient dndgrad_op;
  if (_grad_op[_qp].norm_sq() == 0)
    dndgrad_op = 0;
  else
  {
    dndgrad_op(0) = _grad_op[_qp](1) * _grad_op[_qp](1);
    dndgrad_op(1) = - _grad_op[_qp](0) * _grad_op[_qp](1);
    dndgrad_op /= (_grad_op[_qp].norm_sq() * _grad_op[_qp].norm());
  }

  // Calculate interfacial parameter epsilon and its derivatives
  _eps[_qp]= _eps_bar * (_delta * std::cos(_j * (angle - _theta0 * libMesh::pi/180.0)) + 1.0);
  _deps[_qp]= - _eps_bar * _delta * _delta * std::sin(_j * (angle - _theta0 * libMesh::pi/180.0));
  Real d2eps = - _eps_bar * _delta * _delta * _delta * std::cos(_j * (angle - _theta0 * libMesh::pi/180.0));

  // Compute derivatives of epsilon and its derivative wrt grad_op
  _depsdgrad_op[_qp] = _deps[_qp] * dangledn * dndgrad_op;
  _ddepsdgrad_op[_qp] = d2eps * dangledn * dndgrad_op;

  // Compute mobility
  if (_prop_F)
    (*_prop_F)[_qp] = _eps_bar * _eps_bar / (_tau0 * _eps[_qp] * _eps[_qp]);
}
