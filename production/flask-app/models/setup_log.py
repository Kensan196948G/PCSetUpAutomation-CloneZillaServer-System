"""Setup Log database model."""
from datetime import datetime
from . import db


class SetupLog(db.Model):
    """Setup Log table - stores setup progress logs.

    Attributes:
        id: Primary key
        serial: PC serial number
        pcname: PC name
        status: Setup status (pending/in_progress/completed/failed)
        timestamp: Log timestamp
        logs: Log messages (text)
        step: Current setup step
        error_message: Error message if failed
    """

    __tablename__ = 'setup_logs'

    id = db.Column(db.Integer, primary_key=True)
    serial = db.Column(db.String(100), nullable=False, index=True)
    pcname = db.Column(db.String(50), nullable=False, index=True)
    status = db.Column(
        db.String(20),
        nullable=False,
        default='pending',
        index=True
    )
    timestamp = db.Column(
        db.DateTime,
        nullable=False,
        default=datetime.utcnow,
        index=True
    )
    logs = db.Column(db.Text, nullable=True)
    step = db.Column(db.String(50), nullable=True)
    error_message = db.Column(db.Text, nullable=True)

    # Valid status values
    STATUS_PENDING = 'pending'
    STATUS_IN_PROGRESS = 'in_progress'
    STATUS_COMPLETED = 'completed'
    STATUS_FAILED = 'failed'

    def __repr__(self):
        """String representation."""
        return f'<SetupLog {self.pcname} - {self.status} ({self.timestamp})>'

    def to_dict(self):
        """Convert to dictionary."""
        return {
            'id': self.id,
            'serial': self.serial,
            'pcname': self.pcname,
            'status': self.status,
            'timestamp': self.timestamp.isoformat() if self.timestamp else None,
            'logs': self.logs,
            'step': self.step,
            'error_message': self.error_message
        }

    @classmethod
    def create_log(cls, serial, pcname, status, logs=None, step=None, error_message=None):
        """Create a new setup log entry.

        Args:
            serial: PC serial number
            pcname: PC name
            status: Setup status
            logs: Optional log messages
            step: Optional current step
            error_message: Optional error message

        Returns:
            SetupLog object
        """
        log = cls(
            serial=serial,
            pcname=pcname,
            status=status,
            logs=logs,
            step=step,
            error_message=error_message
        )
        db.session.add(log)
        db.session.commit()
        return log

    @classmethod
    def get_latest_by_serial(cls, serial):
        """Get the latest log for a serial number.

        Args:
            serial: PC serial number

        Returns:
            SetupLog object or None
        """
        return cls.query.filter_by(serial=serial).order_by(
            cls.timestamp.desc()
        ).first()

    @classmethod
    def get_logs_by_status(cls, status, limit=100):
        """Get logs by status.

        Args:
            status: Setup status
            limit: Maximum number of logs to return

        Returns:
            List of SetupLog objects
        """
        return cls.query.filter_by(status=status).order_by(
            cls.timestamp.desc()
        ).limit(limit).all()
