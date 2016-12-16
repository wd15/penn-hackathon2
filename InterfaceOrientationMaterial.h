/****************************************************************/
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*          All contents are licensed under LGPL V2.1           */
/*             See LICENSE for full restrictions                */
/****************************************************************/
#ifndef INTERFACEORIENTATIONMATERIAL_H
#define INTERFACEORIENTATIONMATERIAL_H

#include "Material.h"
#include "ParsedMaterialHelper.h"
/*NOTE: This file was modified for the Phase Field Hackathon III
        It is not meant for general use in the MOOSE framework. */
        
//Forward Declarations
class InterfaceOrientationMaterial;

template<>
InputParameters validParams<InterfaceOrientationMaterial>();

/**
 * Material to compute the angular orientation of order parameter interfaces.
 */
class InterfaceOrientationMaterial : public Material
{
public:
  InterfaceOrientationMaterial(const InputParameters & parameters);

protected:
  virtual void computeQpProperties();

private:
  Real _delta;
  unsigned int _j;
  Real _theta0;
  Real _eps_bar;

  MaterialProperty<Real> & _eps;
  MaterialProperty<Real> & _deps;
  MaterialProperty<RealGradient> & _depsdgrad_op;
  MaterialProperty<RealGradient> & _ddepsdgrad_op;

  const VariableValue & _op;
  const VariableGradient & _grad_op;
  std::string _mob_name;
  MaterialProperty<Real> * _prop_F;
  Real _tau0;

};

#endif //INTERFACEORIENTATIONMATERIAL_H
