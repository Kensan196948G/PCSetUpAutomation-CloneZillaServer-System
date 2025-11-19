"""PC Master database model."""
from datetime import datetime
from . import db


class PCMaster(db.Model):
    """PC Master table - stores PC information.

    Attributes:
        id: Primary key
        serial: PC serial number (unique)
        pcname: PC name in YYYYMMDDM format
        odj_path: Path to ODJ file
        created_at: Record creation timestamp
        updated_at: Record update timestamp
    """

    __tablename__ = 'pc_master'

    id = db.Column(db.Integer, primary_key=True)
    serial = db.Column(db.String(100), unique=True, nullable=False, index=True)
    pcname = db.Column(db.String(50), nullable=False, index=True)
    odj_path = db.Column(db.String(255), nullable=True)
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

    # Relationship with setup logs
    setup_logs = db.relationship(
        'SetupLog',
        backref='pc',
        lazy='dynamic',
        foreign_keys='SetupLog.serial',
        primaryjoin='PCMaster.serial == foreign(SetupLog.serial)'
    )

    def __repr__(self):
        """String representation."""
        return f'<PCMaster {self.pcname} ({self.serial})>'

    def to_dict(self):
        """Convert to dictionary."""
        return {
            'id': self.id,
            'serial': self.serial,
            'pcname': self.pcname,
            'odj_path': self.odj_path,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

    @staticmethod
    def generate_pcname(date=None):
        """Generate PC name in YYYYMMDDM format.

        Args:
            date: Date object (defaults to today)

        Returns:
            str: PC name in YYYYMMDDM format (e.g., '20251116M')
        """
        if date is None:
            date = datetime.now()
        return date.strftime('%Y%m%d') + 'M'

    @classmethod
    def find_by_serial(cls, serial):
        """Find PC by serial number.

        Args:
            serial: PC serial number

        Returns:
            PCMaster object or None
        """
        return cls.query.filter_by(serial=serial).first()

    @classmethod
    def find_by_pcname(cls, pcname):
        """Find PC by PC name.

        Args:
            pcname: PC name

        Returns:
            PCMaster object or None
        """
        return cls.query.filter_by(pcname=pcname).first()
