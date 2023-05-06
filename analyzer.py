import os
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

sns.set()

SPARSE_WIND = os.path.join( "data", "sparse_wind.csv" )

def load_data( path: str ) -> pd.DataFrame:
    dataset = pd.read_csv( path, index_col=0, header=None, skiprows=6, nrows=11 ).T
    dataset = dataset.drop( "[run number]", axis=1 ) \
                     .drop( "[mean]", axis=1 ) \
                     .drop( "[steps]", axis=1 ) \
                     .drop( "[min]", axis=1 ) \
                     .drop( "[max]", axis=1 ) \
                     .drop( "[reporter]", axis=1 )

    for col in [ "density", "wind-velocity", "[final]" ]:
        dataset[ col ] = pd.to_numeric( dataset[ col ] )

    return dataset


sparse_wind = load_data( SPARSE_WIND )

def plot_density_dependency( data: pd.DataFrame ) -> None:
    pass


def groupper( row: np.array ) -> np.array:
    pass

def plot_velocity_dependency( data: pd.DataFrame ) -> None:

    lower = np.arange(0, 100, 10)
    upper = np.arange( 10, 110, 10 )
    bounds = zip( lower, upper )

    def groupper( row: pd.Series ) -> pd.Series:

        for low, high in zip(lower, upper):
            if low <= row[ "wind-velocity" ] and row[ "wind-velocity" ] <= high:
                return f"{low}, {high}"

    groupped = data.apply( groupper, axis=1 )
    print( groupped )
    ##sns.scatterplot( data=data, x="wind-velocity", y="[final]", hue="density" )
    ##plt.show()

plot_velocity_dependency( sparse_wind )
