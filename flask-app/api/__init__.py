"""API Blueprint package."""
from flask import Blueprint

api_bp = Blueprint('api', __name__)

# Import routes
from . import pcinfo  # noqa: F401, E402
from . import log  # noqa: F401, E402
from . import pc_crud  # noqa: F401, E402
from . import import_export  # noqa: F401, E402
from . import odj  # noqa: F401, E402
from . import images  # noqa: F401, E402
from . import deployment  # noqa: F401, E402

__all__ = ['api_bp']
