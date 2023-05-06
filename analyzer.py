import os
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

sns.set()

## --- Path loading
SPARSE_WIND = os.path.join( "data", "sparse_wind.csv" )
SPARSE_UNIFORM = os.path.join( "data", "sparse_uniform.csv" )
SPARSE_DENSITY = os.path.join( "data", "sparse_density.csv" )
SPARSE_NO = os.path.join( "data", "sparse_no.csv" )
SPARSE_DENSITY_WIND = os.path.join( "data", "sparse_density_wind.csv" )

DENSE_WIND = os.path.join( "data", "dense_wind.csv" )
DENSE_DENSITY = os.path.join( "data", "dense_density.csv" )
DENSE_UNIFORM = os.path.join( "data", "dense_uniform.csv" )
DENSE_DENSITY_WIND = os.path.join( "data", "dense_density_wind.csv" )
DENSE_NO = os.path.join( "data", "dense_no.csv" )
## ---

def load_data( path: str ) -> pd.DataFrame:
    dataset = pd.read_csv( path )
    dataset = dataset.drop( "[run number]", axis=1 ) \
                     .drop( "[step]", axis=1 )

    dataset[ "[final]" ] = (dataset[ "burned-trees" ] / dataset[ "initial-trees" ]) * 100
    for col in [ "density", "wind-velocity", "[final]" ]:
        dataset[ col ] = pd.to_numeric( dataset[ col ] )

    dataset = dataset.drop( "initial-trees", axis=1 ) \
                     .drop( "burned-trees", axis=1 ) \
                     .drop( "wind-direction", axis=1 )

    return dataset

## --- Data loading
sparse_wind = load_data( SPARSE_WIND )
sparse_density = load_data( SPARSE_DENSITY )
sparse_density_wind = load_data( SPARSE_DENSITY_WIND )
sparse_uniform = load_data( SPARSE_UNIFORM )
sparse_no = load_data( SPARSE_NO )

dense_wind = load_data( DENSE_WIND )
dense_density = load_data( DENSE_DENSITY )
dense_uniform = load_data( DENSE_UNIFORM )
dense_density_wind = load_data( DENSE_DENSITY_WIND )
dense_no = load_data( DENSE_NO )
## ---

def plot_dependency( data: pd.DataFrame ) -> None:
    """
    Plots dependency of burned trees on density and wind-velocity
    """

    title = data[ "fighting-strategy" ].iloc[0]
    ax = sns.scatterplot( data=data, x="density", y="[final]", hue="wind-velocity" )
    ax.set_title( f"Strategy: {title}" )
    ax.set_ylabel( "Burnt trees %" )
    plt.show()


def get_avg_burned( data: pd.DataFrame ) -> float:
    """
    For given returns arithmetic mean and median (0.5-quantile) of burned area
    """
    return data[ "[final]" ].median(), np.sum( data[ "[final]" ] ) / len( data[ "[final]" ] )


strategies = [ "Wind", "Fire density", "Density & wind", "Uniform", "No fighting" ]
environments = [ "Sparse", "Dense" ]

datasets = { ("Sparse", "Wind"): sparse_wind,
             ("Sparse", "Fire density"): sparse_density,
             ("Sparse", "Density & wind"): sparse_density_wind,
             ("Sparse", "Uniform"): sparse_uniform,
             ("Sparse", "No fighting"): sparse_no,

             ("Dense", "Wind"): dense_wind,
             ("Dense", "Fire density"): dense_density,
             ("Dense", "Density & wind"): dense_density_wind,
             ("Dense", "Uniform"): dense_uniform,
             ("Dense", "No fighting"): dense_no,
 }

def burn_matrix( kind: int ):
    matrix = np.empty( shape=(5, 2) )
    matrix.fill( 1 )

    for i, env in enumerate( environments ):
        for j, strat in enumerate( strategies ):
            dataset = datasets[ (env, strat) ]
            matrix[ j, i ] = get_avg_burned( dataset )[kind]

    return pd.DataFrame( data=matrix, index=strategies, columns=environments )


def get_markdown( data: pd.DataFrame ) -> str:
    return data.to_markdown()
