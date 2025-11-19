"""Views Blueprint package."""
from flask import Blueprint

views_bp = Blueprint('views', __name__)

# Import routes
from . import main  # noqa: F401, E402
from . import pc_management  # noqa: F401, E402
from . import import_export  # noqa: F401, E402
from . import deployment  # noqa: F401, E402

__all__ = ['views_bp']
