import dash
from dash import dcc, html, Input, Output
import plotly.graph_objects as go
import pandas as pd
import numpy as np

# Gerar dados fictícios para o dashboard

np.random.seed(42)

# Criar dataset com 100+ registros

dates = pd.date_range(start="2024-01-01", end="2024-12-31", freq="D")[:365]
n_records = len(dates)

# Dados de vendas por produto

produtos = ["Produto A", "Produto B", "Produto C", "Produto D", "Produto E"]
regioes = ["Norte", "Sul", "Leste", "Oeste", "Centro"]
categorias = ["Eletrônicos", "Vestuário", "Alimentos", "Móveis", "Livros"]

data = {
    "data": dates,
    "produto": np.random.choice(produtos, n_records),
    "regiao": np.random.choice(regioes, n_records),
    "categoria": np.random.choice(categorias, n_records),
    "vendas": np.random.uniform(1000, 50000, n_records),
    "quantidade": np.random.randint(1, 100, n_records),
    "custo": np.random.uniform(500, 25000, n_records),
    "satisfacao_cliente": np.random.uniform(3.0, 5.0, n_records),
}

df = pd.DataFrame(data)
df["lucro"] = df["vendas"] - df["custo"]
df["mes"] = df["data"].dt.month
df["mes_nome"] = df["data"].dt.strftime("%B")

# Inicializar app Dash

app = dash.Dash(__name__, suppress_callback_exceptions=True)
server = app.server  # Expor server para gunicorn

# Definir cores do tema CLARO

colors = {
    "background": "#f8f9fa",
    "text": "#212529",
    "primary": "#0066cc",
    "secondary": "#dc3545",
    "success": "#28a745",
    "card": "#ffffff",
    "accent": "#ffc107",
    "border": "#dee2e6",
}

# Layout do Dashboard

app.layout = html.Div(
    style={
        "backgroundColor": colors["background"],
        "fontFamily": "Arial, sans-serif",
        "padding": "20px",
    },
    children=[
        # Cabeçalho
        html.Div(
            [
                html.H1(
                    "Dashboard de Análise de Vendas",
                    style={
                        "textAlign": "center",
                        "color": colors["primary"],
                        "marginBottom": "10px",
                        "fontSize": "48px",
                        "fontWeight": "bold",
                    },
                ),
                html.P(
                    "Análise Completa de Vendas e Performance",
                    style={
                        "textAlign": "center",
                        "color": colors["text"],
                        "fontSize": "18px",
                        "marginBottom": "30px",
                    },
                ),
            ]
        ),
        # Cards com KPIs
        html.Div(
            [
                html.Div(
                    [
                        html.Div(
                            [
                                html.H3(
                                    "Vendas Totais",
                                    style={"color": colors["text"], "fontSize": "16px"},
                                ),
                                html.H2(
                                    f'R$ {df["vendas"].sum():,.2f}',
                                    style={
                                        "color": colors["primary"],
                                        "fontSize": "28px",
                                        "fontWeight": "bold",
                                    },
                                ),
                                html.P(
                                    f"↑ {np.random.uniform(5, 15):.1f}% vs mês anterior",
                                    style={
                                        "color": colors["success"],
                                        "fontSize": "14px",
                                    },
                                ),
                            ],
                            style={
                                "backgroundColor": colors["card"],
                                "padding": "20px",
                                "borderRadius": "10px",
                                "boxShadow": "0 2px 4px rgba(0, 0, 0, 0.1)",
                                "border": f'1px solid {colors["border"]}',
                                "margin": "10px",
                            },
                        )
                    ],
                    style={"flex": "1"},
                ),
                html.Div(
                    [
                        html.Div(
                            [
                                html.H3(
                                    "Lucro Total",
                                    style={"color": colors["text"], "fontSize": "16px"},
                                ),
                                html.H2(
                                    f'R$ {df["lucro"].sum():,.2f}',
                                    style={
                                        "color": colors["success"],
                                        "fontSize": "28px",
                                        "fontWeight": "bold",
                                    },
                                ),
                                html.P(
                                    f"↑ {np.random.uniform(3, 12):.1f}% vs mês anterior",
                                    style={
                                        "color": colors["success"],
                                        "fontSize": "14px",
                                    },
                                ),
                            ],
                            style={
                                "backgroundColor": colors["card"],
                                "padding": "20px",
                                "borderRadius": "10px",
                                "boxShadow": "0 2px 4px rgba(0, 0, 0, 0.1)",
                                "border": f'1px solid {colors["border"]}',
                                "margin": "10px",
                            },
                        )
                    ],
                    style={"flex": "1"},
                ),
                html.Div(
                    [
                        html.Div(
                            [
                                html.H3(
                                    "Produtos Vendidos",
                                    style={"color": colors["text"], "fontSize": "16px"},
                                ),
                                html.H2(
                                    f'{df["quantidade"].sum():,}',
                                    style={
                                        "color": colors["accent"],
                                        "fontSize": "28px",
                                        "fontWeight": "bold",
                                    },
                                ),
                                html.P(
                                    f"↑ {np.random.uniform(2, 10):.1f}% vs mês anterior",
                                    style={
                                        "color": colors["success"],
                                        "fontSize": "14px",
                                    },
                                ),
                            ],
                            style={
                                "backgroundColor": colors["card"],
                                "padding": "20px",
                                "borderRadius": "10px",
                                "boxShadow": "0 2px 4px rgba(0, 0, 0, 0.1)",
                                "border": f'1px solid {colors["border"]}',
                                "margin": "10px",
                            },
                        )
                    ],
                    style={"flex": "1"},
                ),
                html.Div(
                    [
                        html.Div(
                            [
                                html.H3(
                                    "Satisfação Média",
                                    style={"color": colors["text"], "fontSize": "16px"},
                                ),
                                html.H2(
                                    f'{df["satisfacao_cliente"].mean():.2f}/5.0',
                                    style={
                                        "color": colors["secondary"],
                                        "fontSize": "28px",
                                        "fontWeight": "bold",
                                    },
                                ),
                                html.P(
                                    "⭐ Excelente avaliação",
                                    style={
                                        "color": colors["success"],
                                        "fontSize": "14px",
                                    },
                                ),
                            ],
                            style={
                                "backgroundColor": colors["card"],
                                "padding": "20px",
                                "borderRadius": "10px",
                                "boxShadow": "0 2px 4px rgba(0, 0, 0, 0.1)",
                                "border": f'1px solid {colors["border"]}',
                                "margin": "10px",
                            },
                        )
                    ],
                    style={"flex": "1"},
                ),
            ],
            style={"display": "flex", "flexWrap": "wrap", "marginBottom": "30px"},
        ),
        # Filtros
        html.Div(
            [
                html.Div(
                    [
                        html.Label(
                            "Selecione a Região:",
                            style={"color": colors["text"], "fontWeight": "bold"},
                        ),
                        dcc.Dropdown(
                            id="regiao-dropdown",
                            options=[{"label": "Todas", "value": "Todas"}]
                            + [{"label": r, "value": r} for r in regioes],
                            value="Todas",
                            style={
                                "backgroundColor": colors["card"],
                                "color": colors["text"],
                            },
                        ),
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
                html.Div(
                    [
                        html.Label(
                            "Selecione a Categoria:",
                            style={"color": colors["text"], "fontWeight": "bold"},
                        ),
                        dcc.Dropdown(
                            id="categoria-dropdown",
                            options=[{"label": "Todas", "value": "Todas"}]
                            + [{"label": c, "value": c} for c in categorias],
                            value="Todas",
                            style={
                                "backgroundColor": colors["card"],
                                "color": colors["text"],
                            },
                        ),
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
            ],
            style={"display": "flex", "flexWrap": "wrap", "marginBottom": "30px"},
        ),
        # Gráficos - Linha 1
        html.Div(
            [
                html.Div(
                    [
                        dcc.Loading(
                            id="loading-1",
                            type="circle",
                            color=colors["primary"],
                            children=[dcc.Graph(id="vendas-tempo")],
                        )
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
            ],
            style={"display": "flex", "flexWrap": "wrap"},
        ),
        # Gráficos - Linha 2
        html.Div(
            [
                html.Div(
                    [
                        dcc.Loading(
                            id="loading-2",
                            type="circle",
                            color=colors["primary"],
                            children=[dcc.Graph(id="vendas-produto")],
                        )
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
                html.Div(
                    [
                        dcc.Loading(
                            id="loading-3",
                            type="circle",
                            color=colors["primary"],
                            children=[dcc.Graph(id="vendas-regiao")],
                        )
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
            ],
            style={"display": "flex", "flexWrap": "wrap"},
        ),
        # Gráficos - Linha 3
        html.Div(
            [
                html.Div(
                    [
                        dcc.Loading(
                            id="loading-4",
                            type="circle",
                            color=colors["primary"],
                            children=[dcc.Graph(id="lucro-categoria")],
                        )
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
                html.Div(
                    [
                        dcc.Loading(
                            id="loading-5",
                            type="circle",
                            color=colors["primary"],
                            children=[dcc.Graph(id="satisfacao-produto")],
                        )
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
            ],
            style={"display": "flex", "flexWrap": "wrap"},
        ),
        # Gráficos - Linha 4
        html.Div(
            [
                html.Div(
                    [
                        dcc.Loading(
                            id="loading-6",
                            type="circle",
                            color=colors["primary"],
                            children=[dcc.Graph(id="heatmap-vendas")],
                        )
                    ],
                    style={"flex": "1", "margin": "10px"},
                ),
            ],
            style={"display": "flex", "flexWrap": "wrap"},
        ),
    ],
)

# Callbacks para interatividade


@app.callback(
    [
        Output("vendas-tempo", "figure"),
        Output("vendas-produto", "figure"),
        Output("vendas-regiao", "figure"),
        Output("lucro-categoria", "figure"),
        Output("satisfacao-produto", "figure"),
        Output("heatmap-vendas", "figure"),
    ],
    [Input("regiao-dropdown", "value"), Input("categoria-dropdown", "value")],
)
def update_graphs(regiao_selecionada, categoria_selecionada):
    # Filtrar dados

    df_filtrado = df.copy()

    if regiao_selecionada != "Todas":
        df_filtrado = df_filtrado[df_filtrado["regiao"] == regiao_selecionada]
    if categoria_selecionada != "Todas":
        df_filtrado = df_filtrado[df_filtrado["categoria"] == categoria_selecionada]
    # 1. Gráfico de linha - Vendas ao longo do tempo

    vendas_tempo = df_filtrado.groupby("data")["vendas"].sum().reset_index()
    fig1 = go.Figure()
    fig1.add_trace(
        go.Scatter(
            x=vendas_tempo["data"],
            y=vendas_tempo["vendas"],
            mode="lines+markers",
            name="Vendas",
            line=dict(color=colors["primary"], width=3),
            marker=dict(size=6),
            fill="tozeroy",
            fillcolor="rgba(0, 212, 255, 0.2)",
        )
    )
    fig1.update_layout(
        title="Evolução de Vendas ao Longo do Tempo",
        template="plotly_white",
        paper_bgcolor=colors["card"],
        plot_bgcolor=colors["card"],
        font=dict(color=colors["text"]),
        hovermode="x unified",
    )

    # 2. Gráfico de barras - Vendas por produto

    vendas_produto = df_filtrado.groupby("produto")["vendas"].sum().reset_index()
    vendas_produto = vendas_produto.sort_values("vendas", ascending=True)
    fig2 = go.Figure()
    fig2.add_trace(
        go.Bar(
            y=vendas_produto["produto"],
            x=vendas_produto["vendas"],
            orientation="h",
            marker=dict(
                color=vendas_produto["vendas"], colorscale="Blues", showscale=True
            ),
            text=vendas_produto["vendas"].apply(lambda x: f"R$ {x:,.0f}"),
            textposition="auto",
        )
    )
    fig2.update_layout(
        title="Vendas por Produto",
        template="plotly_white",
        paper_bgcolor=colors["card"],
        plot_bgcolor=colors["card"],
        font=dict(color=colors["text"]),
    )

    # 3. Gráfico de pizza - Vendas por região

    vendas_regiao = df_filtrado.groupby("regiao")["vendas"].sum().reset_index()
    fig3 = go.Figure()
    fig3.add_trace(
        go.Pie(
            labels=vendas_regiao["regiao"],
            values=vendas_regiao["vendas"],
            hole=0.4,
            marker=dict(colors=["#0066cc", "#dc3545", "#28a745", "#ffc107", "#17a2b8"]),
            textinfo="label+percent",
            textfont=dict(size=14),
        )
    )
    fig3.update_layout(
        title="Distribuição de Vendas por Região",
        template="plotly_white",
        paper_bgcolor=colors["card"],
        font=dict(color=colors["text"]),
    )

    # 4. Gráfico de barras empilhadas - Lucro por categoria

    lucro_categoria = (
        df_filtrado.groupby(["categoria", "mes_nome"])
        .agg({"lucro": "sum"})
        .reset_index()
    )

    fig4 = go.Figure()
    for categoria in df_filtrado["categoria"].unique():
        data_cat = lucro_categoria[lucro_categoria["categoria"] == categoria]
        fig4.add_trace(
            go.Bar(x=data_cat["mes_nome"], y=data_cat["lucro"], name=categoria)
        )
    fig4.update_layout(
        title="Lucro por Categoria (Mensal)",
        barmode="stack",
        template="plotly_white",
        paper_bgcolor=colors["card"],
        plot_bgcolor=colors["card"],
        font=dict(color=colors["text"]),
        xaxis_tickangle=-45,
    )

    # 5. Gráfico de dispersão - Satisfação por produto

    satisfacao_produto = (
        df_filtrado.groupby("produto")
        .agg({"satisfacao_cliente": "mean", "vendas": "sum", "quantidade": "sum"})
        .reset_index()
    )

    fig5 = go.Figure()
    fig5.add_trace(
        go.Scatter(
            x=satisfacao_produto["vendas"],
            y=satisfacao_produto["satisfacao_cliente"],
            mode="markers+text",
            marker=dict(
                size=satisfacao_produto["quantidade"] / 10,
                color=satisfacao_produto["satisfacao_cliente"],
                colorscale="RdYlGn",
                showscale=True,
                line=dict(width=2, color="#666"),
            ),
            text=satisfacao_produto["produto"],
            textposition="top center",
        )
    )
    fig5.update_layout(
        title="Satisfação do Cliente vs Vendas por Produto",
        xaxis_title="Vendas Totais (R$)",
        yaxis_title="Satisfação Média",
        template="plotly_white",
        paper_bgcolor=colors["card"],
        plot_bgcolor=colors["card"],
        font=dict(color=colors["text"]),
    )

    # 6. Heatmap - Vendas por região e categoria

    heatmap_data = df_filtrado.pivot_table(
        values="vendas", index="regiao", columns="categoria", aggfunc="sum"
    ).fillna(0)

    fig6 = go.Figure()
    fig6.add_trace(
        go.Heatmap(
            z=heatmap_data.values,
            x=heatmap_data.columns,
            y=heatmap_data.index,
            colorscale="Blues",
            text=heatmap_data.values,
            texttemplate="R$ %{text:,.0f}",
            textfont=dict(size=10),
            colorbar=dict(title="Vendas (R$)"),
        )
    )
    fig6.update_layout(
        title="Mapa de Calor: Vendas por Região e Categoria",
        template="plotly_white",
        paper_bgcolor=colors["card"],
        plot_bgcolor=colors["card"],
        font=dict(color=colors["text"]),
    )

    return fig1, fig2, fig3, fig4, fig5, fig6


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8050, debug=False)
