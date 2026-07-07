import logging

from celery import shared_task

logger = logging.getLogger(__name__)


@shared_task
def expire_unfunded_group_gifts():
    from .services.refunds import expire_unfunded_group_gifts as run

    result = run()
    logger.info("Expired unfunded group gifts: %s", result)
    return result