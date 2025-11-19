"""Deployment database model."""
from datetime import datetime
from . import db


class Deployment(db.Model):
    """Deployment table - stores deployment configurations and status.

    Attributes:
        id: Primary key
        name: Deployment name
        image_name: Clonezilla image name
        mode: Deployment mode (multicast/unicast)
        target_serials: Comma-separated list of target PC serials
        status: Deployment status (pending/running/completed/failed)
        started_at: Deployment start timestamp
        completed_at: Deployment completion timestamp
        created_at: Record creation timestamp
        updated_at: Record update timestamp
        created_by: User who created the deployment
        notes: Additional notes
    """

    __tablename__ = 'deployment'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    image_name = db.Column(db.String(100), nullable=False)
    mode = db.Column(db.String(20), nullable=False, default='multicast')
    target_serials = db.Column(db.Text, nullable=True)
    target_count = db.Column(db.Integer, default=0)
    status = db.Column(
        db.String(20),
        nullable=False,
        default='pending',
        index=True
    )
    progress = db.Column(db.Integer, default=0)  # 0-100
    started_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(
        db.DateTime,
        nullable=False,
        default=datetime.utcnow
    )
    updated_at = db.Column(
        db.DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )
    created_by = db.Column(db.String(50), nullable=True)
    notes = db.Column(db.Text, nullable=True)

    def __repr__(self):
        """String representation."""
        return f'<Deployment {self.name} ({self.status})>'

    def to_dict(self):
        """Convert to dictionary."""
        return {
            'id': self.id,
            'name': self.name,
            'image_name': self.image_name,
            'mode': self.mode,
            'target_serials': self.target_serials.split(',') if self.target_serials else [],
            'target_count': self.target_count,
            'status': self.status,
            'progress': self.progress,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'created_by': self.created_by,
            'notes': self.notes
        }

    @classmethod
    def get_active_deployments(cls):
        """Get all active deployments.

        Returns:
            List of Deployment objects with status 'running'
        """
        return cls.query.filter(
            cls.status.in_(['pending', 'running'])
        ).order_by(cls.created_at.desc()).all()

    @classmethod
    def get_recent_deployments(cls, limit=10):
        """Get recent deployments.

        Args:
            limit: Number of deployments to return

        Returns:
            List of Deployment objects
        """
        return cls.query.order_by(
            cls.created_at.desc()
        ).limit(limit).all()
