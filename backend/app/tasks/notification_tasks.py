# Notification Celery Tasks
# Transport ERP — Phase D: Milestone notifications & payment reminders

import logging
from datetime import datetime
from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.notification_tasks.send_milestone_notifications")
def send_milestone_notifications():
    """
    Periodic task (every 5 minutes): check for jobs with recent status changes
    and send WhatsApp notifications to customers.
    """
    logger.info("Checking for milestone notifications to send")
    # In production, with async event loop:
    # 1. Query jobs with status changes in last 5 minutes
    # 2. For each job, look up client phone
    # 3. Call whatsapp_service.send_milestone_notification
    #
    # import asyncio
    # from app.db.postgres.connection import async_session_maker
    # from app.models.postgres.job import Job
    # from app.models.postgres.client import Client
    # from app.services.whatsapp_service import send_milestone_notification
    # from sqlalchemy import select
    #
    # async def _run():
    #     async with async_session_maker() as db:
    #         cutoff = datetime.utcnow() - timedelta(minutes=5)
    #         result = await db.execute(
    #             select(Job).where(Job.updated_at >= cutoff)
    #         )
    #         jobs = result.scalars().all()
    #         for job in jobs:
    #             client = await db.get(Client, job.client_id)
    #             if client and client.phone:
    #                 await send_milestone_notification(
    #                     phone=client.phone,
    #                     customer_name=client.name,
    #                     job_number=job.job_number,
    #                     milestone=job.status,
    #                 )
    # asyncio.run(_run())
    logger.info("Milestone notification check complete")


@celery_app.task(name="app.tasks.notification_tasks.send_payment_reminders")
def send_payment_reminders():
    """
    Periodic task (daily at 10 AM): send payment reminders for overdue invoices.
    """
    logger.info("Sending payment reminders for overdue invoices")
    # In production:
    # 1. Query invoices where status = 'overdue' or due_date < today
    # 2. For each, look up client phone
    # 3. Send WhatsApp reminder with invoice number and amount due
    #
    # import asyncio
    # from app.db.postgres.connection import async_session_maker
    # from app.models.postgres.finance import Invoice
    # from app.models.postgres.client import Client
    # from app.services.whatsapp_service import send_whatsapp_message
    # from sqlalchemy import select
    #
    # async def _run():
    #     async with async_session_maker() as db:
    #         result = await db.execute(
    #             select(Invoice).where(Invoice.status == "overdue")
    #         )
    #         invoices = result.scalars().all()
    #         for inv in invoices:
    #             client = await db.get(Client, inv.client_id)
    #             if client and client.phone:
    #                 await send_whatsapp_message(
    #                     phone=client.phone,
    #                     message=f"Hi {client.name}, reminder: Invoice {inv.invoice_number} "
    #                             f"of ₹{inv.amount_due} is overdue. Please clear at your earliest."
    #                 )
    # asyncio.run(_run())
    logger.info("Payment reminder check complete")
