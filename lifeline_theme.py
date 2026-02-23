"""
Lifeline Plotly Theme
=====================
Registers a "lifeline" template with Plotly so any chart can match the
Lifeline brand with a single argument: template="lifeline".

Quick start (inside notebooks/)
--------------------------------
    import sys; sys.path.insert(0, "..")
    import lifeline_theme

    lifeline_theme.inject_fonts()   # loads Open Sans from Google Fonts

    import plotly.express as px
    fig = px.bar(df, x="page_location", y="page_views",
                 template="lifeline", title="My Chart")
    lifeline_theme.add_lifeline_logo(fig)
    fig.show()

Utilities
---------
    lifeline_theme.strip_domain(df["page_location"])
        Strips scheme + domain from a URL Series, returning just the path.
        Ideal for GA4 page_location columns.
"""

import base64
from pathlib import Path
from urllib.parse import urlparse

import plotly.graph_objects as go
import plotly.io as pio

from lla_data.url_utils import normalize_url_for_join

# ---------------------------------------------------------------------------
# Brand colours
# ---------------------------------------------------------------------------

# Primary palette
SUPPORT_BLUE = "#221FBB"
CALM_BEIGE = "#F3EBD9"
OPTIMISM_ORANGE = "#F45336"

# Secondary palette
CARING_CORAL = "#FF9E85"
MINDFUL_MAUVE = "#A89FF4"
GROWTH_GREEN = "#E3D973"
MELLOW_YELLOW = "#FFD075"

# Light variants (backgrounds, fills)
LIGHT_CARING_CORAL = "#F8D8D0"
LIGHT_MINDFUL_MAUVE = "#DBD8F4"
LIGHT_GROWTH_GREEN = "#EBE6B4"
LIGHT_MELLOW_YELLOW = "#FAE2B5"
LIGHT_CALM_BEIGE = "#FBF9F4"

# Neutral tones derived from brand
_GRID_COLOR = "#DDD5C5"  # warm gridlines matching Calm Beige
_ZERO_LINE_COLOR = "#C8BEA8"  # slightly darker zero line
_AXIS_COLOR = "#8080BB"  # muted blue-toned axis lines / ticks

# All text uses Support Blue — the brand's primary typography colour
_FONT_COLOR = SUPPORT_BLUE

# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------

_FONT_BODY = "Open Sans, sans-serif"
_FONT_HEADING = "Open Sans Condensed, Open Sans, sans-serif"

# ---------------------------------------------------------------------------
# Colorway — ordered for multi-series charts
# Support Blue leads (brand-dominant), then secondary palette
# ---------------------------------------------------------------------------

COLORWAY = [
    SUPPORT_BLUE,
    OPTIMISM_ORANGE,
    CARING_CORAL,
    MINDFUL_MAUVE,
    GROWTH_GREEN,
    MELLOW_YELLOW,
    LIGHT_CARING_CORAL,
    LIGHT_MINDFUL_MAUVE,
    LIGHT_GROWTH_GREEN,
    LIGHT_MELLOW_YELLOW,
]

# ---------------------------------------------------------------------------
# Template
# ---------------------------------------------------------------------------

_layout = go.Layout(
    colorway=COLORWAY,
    # Unified beige background across the whole figure (paper + plot area)
    paper_bgcolor=LIGHT_CALM_BEIGE,
    plot_bgcolor=LIGHT_CALM_BEIGE,
    # Top margin gives the logo room above the plot area
    margin=dict(t=90, r=24, b=60, l=64, pad=0),
    font=dict(
        family=_FONT_BODY,
        color=_FONT_COLOR,
        size=13,
    ),
    title=dict(
        font=dict(
            family=_FONT_HEADING,
            color=SUPPORT_BLUE,
            size=24,
        ),
        x=0.0,
        xanchor="left",
        pad=dict(t=0, l=48, b=12),
    ),
    xaxis=dict(
        gridcolor=_GRID_COLOR,
        # Support Blue accent line along the x-axis
        linecolor=SUPPORT_BLUE,
        linewidth=2,
        showline=True,
        tickcolor=_AXIS_COLOR,
        zeroline=True,
        zerolinecolor=_ZERO_LINE_COLOR,
        zerolinewidth=1,
        tickfont=dict(family=_FONT_BODY, color=_FONT_COLOR, size=12),
        title_font=dict(family=_FONT_BODY, color=_FONT_COLOR, size=13),
        title_standoff=12,
    ),
    yaxis=dict(
        gridcolor=_GRID_COLOR,
        linecolor=_AXIS_COLOR,
        showline=False,
        tickcolor=_AXIS_COLOR,
        zeroline=False,
        tickfont=dict(family=_FONT_BODY, color=_FONT_COLOR, size=12),
        title_font=dict(family=_FONT_BODY, color=_FONT_COLOR, size=13),
        title_standoff=12,
    ),
    legend=dict(
        font=dict(family=_FONT_BODY, color=_FONT_COLOR, size=12),
        bgcolor="rgba(251,249,244,0.85)",
        bordercolor=_GRID_COLOR,
        borderwidth=1,
    ),
    hoverlabel=dict(
        font=dict(family=_FONT_BODY, size=13),
        bgcolor=CALM_BEIGE,
        bordercolor=SUPPORT_BLUE,
        namelength=-1,
    ),
    bargap=0.25,
)

# Trace defaults: remove bar borders for a cleaner look
_bar_defaults = go.Bar(marker=dict(line=dict(width=0)))

template = go.layout.Template(layout=_layout, data={"bar": [_bar_defaults]})
pio.templates["lifeline"] = template

# ---------------------------------------------------------------------------
# Font injection (Jupyter)
# ---------------------------------------------------------------------------

_FONTS_CSS_URL = (
    "https://fonts.googleapis.com/css2"
    "?family=Open+Sans:wght@400;600;700"
    "&family=Open+Sans+Condensed:wght@700"
    "&display=swap"
)


def inject_fonts() -> None:
    """
    Inject Open Sans and Open Sans Condensed from Google Fonts into the
    current Jupyter notebook output.  Call this once at the top of a notebook
    after importing the theme.  Has no effect outside Jupyter.
    """
    try:
        from IPython.display import HTML, display

        display(
            HTML(
                f"""
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="{_FONTS_CSS_URL}" rel="stylesheet">
"""
            )
        )
    except ImportError:
        pass


# ---------------------------------------------------------------------------
# Logo helper
# ---------------------------------------------------------------------------

# Use the brandmark icon only (no text)
_LOGO_PATH = (
    Path(__file__).parent
    / "lla-brand"
    / "Lifeline Brandmark"
    / "RGB"
    / "PNG"
    / "LIFE0043-Lifeline-Brandmark-Blue-RGB.png"
)

# Cache the encoded logo so it isn't re-read on every call
_logo_cache: str | None = None  # reset whenever _LOGO_PATH changes


def _logo_source() -> str | None:
    """Return a base64 data URI for the Lifeline logo, or None if missing."""
    global _logo_cache
    if _logo_cache is not None:
        return _logo_cache
    if not _LOGO_PATH.exists():
        return None
    with open(_LOGO_PATH, "rb") as f:
        encoded = base64.b64encode(f.read()).decode("ascii")
    _logo_cache = f"data:image/png;base64,{encoded}"
    return _logo_cache


def add_lifeline_logo(
    fig: go.Figure,
    *,
    x: float = 1.0,
    y: float = 1.0,
    sizex: float = 0.07,
    sizey: float = 0.10,
    opacity: float = 0.90,
) -> go.Figure:
    """
    Overlay the Lifeline brandmark on a Plotly figure.

    The brandmark is placed in the top-right corner by default (within the
    figure margin, above the plot area).

    Parameters
    ----------
    fig:
        The figure to add the logo to. Modified in place and returned.
    x, y:
        Position in paper coordinates (0–1). Default: top-right.
    sizex, sizey:
        Width and height as a fraction of the paper. Default: ~7% × 10%.
    opacity:
        Logo opacity (0 = invisible, 1 = fully opaque). Default: 0.90.

    Returns
    -------
    The same figure, with the logo added.
    """
    source = _logo_source()
    if source is None:
        return fig

    fig.add_layout_image(
        dict(
            source=source,
            xref="paper",
            yref="paper",
            x=x,
            y=y,
            sizex=sizex,
            sizey=sizey,
            xanchor="right",
            yanchor="bottom",
            opacity=opacity,
            layer="above",
        )
    )
    return fig


# ---------------------------------------------------------------------------
# URL utilities (useful for GA4 page_location columns)
# ---------------------------------------------------------------------------


def strip_domain(series, *, keep_query: bool = True, fallback: str = "(unknown)"):
    """
    Strip the scheme and domain from a Series of URLs, returning the path.

    Useful for making GA4 ``page_location`` values readable on chart axes.

    Parameters
    ----------
    series:
        A pandas Series (or any iterable) of URL strings.
    keep_query:
        If True, appends a truncated query string to the path.
    fallback:
        Value to use when a URL is empty or cannot be parsed.

    Returns
    -------
    A pandas Series with just the path (and optional short query string).

    Example
    -------
        df["label"] = lifeline_theme.strip_domain(df["page_location"])
    """
    import pandas as pd

    def _clean(url: str) -> str:
        if not url or url == "(unknown)":
            return fallback
        try:
            parsed = urlparse(url)
            path = parsed.path or "/"
            if keep_query and parsed.query:
                q = parsed.query[:25] + ("…" if len(parsed.query) > 25 else "")
                return f"{path}?{q}"
            return path
        except Exception:
            return fallback

    if hasattr(series, "map"):
        return series.map(_clean)
    return pd.Series([_clean(u) for u in series])


def canonical_page_path(series, *, fallback: str = "(unknown)"):
    """Map URL-like values to canonical page paths for cross-dataset joins."""
    import pandas as pd

    if hasattr(series, "map"):
        return series.map(
            lambda value: normalize_url_for_join(value, fallback=fallback)
        )
    return pd.Series(
        [normalize_url_for_join(value, fallback=fallback) for value in series]
    )
