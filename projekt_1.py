import pandas as pd
import plotly.express as px
import dash
from dash import dcc, html
from dash.dependencies import Input, Output

# -------------------- NAČTENÍ DAT --------------------
df_covid = pd.read_csv('/Users/janholubik/Downloads/Final_projects_files/project_1_python.csv')

# Pro tab "Případy a úmrtí podle země"
df_dash_1 = df_covid.copy()
countries_list = df_dash_1['location'].drop_duplicates().tolist()

# Pro tab "Mapa kontinentu"
df_dash_2 = df_covid[df_covid['date'] == df_covid['date'].max()].fillna(0)
continent_list = df_dash_2['continent'].drop_duplicates().tolist()
metric_dict = {
    'total_cases': 'Celkový počet případů', 
    'total_deaths': 'Celkový počet úmrtí', 
    'total_tests': 'Celkový počet testů', 
    'total_vaccinations': 'Celkový počet očkování', 
    'people_fully_vaccinated': 'Počet plně očkovaných osob'
}

# Pro tab "Nejvyšší očkování"
df_dash_3 = df_covid.copy()

# -------------------- DASH APP --------------------
app = dash.Dash(__name__)
app.title = "COVID-19 Dashboard"

app.layout = html.Div([
    html.H1("COVID-19 Dashboard", style={'textAlign': 'center'}),
    dcc.Tabs([
        # -------- TAB 1: Případy a úmrtí podle země --------
        dcc.Tab(label='Případy a úmrtí podle země', children=[
            html.Br(),
            html.P("Vyber zemi:"),
            dcc.Dropdown(
                id='country-dropdown',
                options=[{'label': c, 'value': c} for c in countries_list],
                value=countries_list[0]
            ),
            html.Br(),
            html.Div([
                dcc.Graph(id='country-cases', style={'display': 'inline-block', 'width': '48%'}),
                dcc.Graph(id='country-deaths', style={'display': 'inline-block', 'width': '48%'})
            ]),
            html.P("Tento panel zobrazuje kumulativní počet případů COVID-19 a úmrtí v čase pro vybranou zemi.")
        ]),

        # -------- TAB 2: Mapa kontinentu --------
        dcc.Tab(label='Mapa kontinentu', children=[
            html.Br(),
            html.P("Vyber kontinent:"),
            dcc.Dropdown(
                id='continent-dropdown',
                options=[{'label': cont, 'value': cont} for cont in continent_list],
                value=continent_list[0]
            ),
            html.P("Vyber metrický ukazatel:"),
            dcc.Dropdown(
                id='metric-dropdown',
                options=[{'label': v, 'value': k} for k, v in metric_dict.items()],
                value='total_cases'
            ),
            html.Br(),
            dcc.Graph(id='continent-map', style={'height': '600px'}),
            html.P("Tento panel zobrazuje mapu zemí ve vybraném kontinentu. Velikost kruhů odpovídá zvolenému ukazateli (případy, úmrtí, testy, očkování).")
        ]),

        # -------- TAB 3: Nejvyšší očkování --------
        dcc.Tab(label='Nejvyšší očkování', children=[
            html.Br(),
            html.P("Vyber top X zemí:"),
            dcc.Slider(
                id='top-slider',
                min=5, max=20, step=1,
                value=5,
                marks={i: str(i) for i in range(5, 21, 5)}
            ),
            html.Br(),
            html.Div([
                dcc.Graph(id='top-vaccinations', style={'display': 'inline-block', 'width': '48%'}),
                dcc.Graph(id='vaccination-ratio', style={'display': 'inline-block', 'width': '48%'})
            ]),
            html.P("Tento panel zobrazuje země s nejvyšším počtem očkování a poměrem očkovaných k populaci.")
        ])
    ])
])

# -------------------- CALLBACKS --------------------

# Tabulka 1: Případy a úmrtí podle země
@app.callback(
    Output('country-cases', 'figure'),
    Input('country-dropdown', 'value')
)
def update_country_cases(country):
    df = df_dash_1[df_dash_1['location'] == country]
    fig = px.line(
        df, x='date', y='total_cases',
        title=f'Kumulativní počet případů COVID-19 v {country}',
        labels={'total_cases': 'Celkový počet případů', 'date': 'Datum'}
    )
    return fig

@app.callback(
    Output('country-deaths', 'figure'),
    Input('country-dropdown', 'value')
)
def update_country_deaths(country):
    df = df_dash_1[df_dash_1['location'] == country]
    fig = px.line(
        df, x='date', y='total_deaths',
        title=f'Kumulativní počet úmrtí COVID-19 v {country}',
        labels={'total_deaths': 'Celkový počet úmrtí', 'date': 'Datum'}
    )
    return fig

# Tabulka 2: Mapa kontinentu
@app.callback(
    Output('continent-map', 'figure'),
    [Input('continent-dropdown', 'value'),
     Input('metric-dropdown', 'value')]
)
def update_continent_map(continent, metric):
    df = df_dash_2[df_dash_2['continent'] == continent]
    fig = px.scatter_mapbox(
        df,
        lat='latitude', lon='longitude',
        size=df[metric],
        hover_name='location',
        mapbox_style='carto-darkmatter',
        zoom=1,
        height=600,
        title=f'{metric_dict[metric]} v {continent}'
    )
    return fig

# Tabulka 3: Nejvyšší očkování
@app.callback(
    Output('top-vaccinations', 'figure'),
    Input('top-slider', 'value')
)
def update_top_vaccinations(n):
    max_date = df_dash_3['date'].max()
    df = df_dash_3[df_dash_3['date'] == max_date].sort_values('total_vaccinations', ascending=False).head(n)
    fig = px.bar(
        df, x='location', y='total_vaccinations',
        title='Země s nejvyšším počtem očkování',
        labels={'total_vaccinations': 'Celkový počet očkování', 'location': 'Země'}
    )
    return fig

@app.callback(
    Output('vaccination-ratio', 'figure'),
    Input('top-slider', 'value')
)
def update_vaccination_ratio(n):
    max_date = df_dash_3['date'].max()
    df = df_dash_3[df_dash_3['date'] == max_date].copy()
    df['vaccination_ratio'] = df['total_vaccinations'] / df['population']
    df = df.sort_values('vaccination_ratio', ascending=False).head(n)
    fig = px.bar(
        df, x='location', y='vaccination_ratio',
        title='Země s nejvyšším poměrem očkování k populaci',
        labels={'vaccination_ratio': 'Poměr očkovaných k populaci', 'location': 'Země'}
    )
    return fig

# -------------------- RUN SERVER --------------------
if __name__ == '__main__':
    app.run(debug=True)