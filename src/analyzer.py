import os
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

sns.set()

## --- Path loading
WIND = os.path.join( "data", "wind.csv" )
DENSITY = os.path.join( "data", "density.csv" )
UNIFORM = os.path.join( "data", "uniform.csv" )
DENSITY_WIND = os.path.join( "data", "density_wind.csv" )
NO = os.path.join( "data", "no.csv" )

OVERALL = os.path.join( "data", "overall.csv" )
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
wind = load_data( WIND )
density = load_data( DENSITY )
uniform = load_data( UNIFORM )
density_wind = load_data( DENSITY_WIND )
no = load_data( NO )

overall = load_data( OVERALL )
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

def get_deviation( data: pd.DataFrame ) -> float:
    return data[ "[final]" ].std()


strategies = [ "Wind", "Fire density", "Density & wind", "Uniform", "No fighting" ]


datasets = { "Wind": wind,
             "Fire density": density,
             "Density & wind": density_wind,
             "Uniform": uniform,
             "No fighting": no,
 }


def burned():
    matrix = np.empty( shape=(5, 2) )
    matrix.fill( 1 )

    for i, strat in enumerate( strategies ):
        dataset = datasets[ strat ]
        matrix[ i, 0 ] = round( get_avg_burned( dataset )[1], 2 )
        matrix[ i, 1 ] = round( get_avg_burned( dataset )[0], 2 )

    return pd.DataFrame( data=matrix, index=strategies, columns=["Mean % burned", "Median % burned"] )


def get_markdown( data: pd.DataFrame ) -> str:
    return data.to_markdown()


def heatmap_overall( data: pd.DataFrame ) -> None:
    matrix = data.pivot( index="density", columns="wind-velocity", values="[final]" )
    ax = sns.heatmap( matrix, vmin=0, vmax=100 )
    ax.invert_yaxis()
    plt.show()


plot_dependency( wind )
