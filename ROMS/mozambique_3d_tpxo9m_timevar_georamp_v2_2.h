/*
** git $Id$
*******************************************************************************
** Copyright (c) 2002-2025 The ROMS Group                                    **
**   Licensed under a MIT/X style license                                    **
**   See License_ROMS.md                                                     **
*******************************************************************************
**
** Options for tidal signal from TPXO9 3D case with time-dependant ssh and u-v data from HYCOM and near-realistic stratification.
** MoeinDst, 04/05/2026
**
** Application flag:   MOZAMBIQUE_3D_TPXO9M_TIMEVAR_GEORAMP_V2_2
** Input script:       roms_mozambique_3d_tpxo9m_timevar_georamp_v2_2.in
*/

/* ************* netcdf i/o *************** */
#define HDF5
#define DEFLATE
/* **************************************** */

/* ************** Momentum **************** */
#define UV_ADV
#define UV_COR
#define UV_QDRAG
#define UV_VIS2
#define MIX_S_UV
#define SPLINES_VDIFF
#define SPLINES_VVISC
#undef  DIAGNOSTICS_UV
/* **************************************** */

/* ************** Tracers ***************** */
#define DJ_GRADPS
#define SALINITY
#define TS_DIF2
#define MIX_GEO_TS
#undef  DIAGNOSTICS_TS
#undef  TS_MIX_CLIMA /* diffuses perturbation t−tclm */
/* **************************************** */

/* ************** Numerics **************** */
#define PERFECT_RESTART
#define MASKING
#define SOLVE3D
#define NONLIN_EOS
/* **************************************** */

/* ************* Functions **************** */
#undef  ANA_INITIAL /* using ic file */
#define ANA_SMFLUX
#define ANA_STFLUX
#define ANA_SSFLUX
#define ANA_BTFLUX
#define ANA_BSFLUX
#undef  ANA_TCLIMA /* using clima file */
/* **************************************** */

/* *************** TIDES ****************** */
#define SSH_TIDES
#define UV_TIDES
#define RAMP_TIDES
#define ADD_FSOBC
#define ADD_M2OBC
#define TIDE_GENERATING_FORCES
/* **************************************** */

/* ************** MIXING ****************** */
#define GLS_MIXING
#if defined GLS_MIXING || defined MY25_MIXING
# define KANTHA_CLAYSON
# define N2S2_HORAVG
# define RI_SPLINES
#else
# define ANA_VMIX
#endif
/* **************************************** */
