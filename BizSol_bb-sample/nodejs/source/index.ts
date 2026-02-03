import { Camunda8 } from '@camunda8/sdk'
import { startWorkers } from './workers'

const client = new Camunda8().getCamundaRestClient()

/* We inject the client to allow the workers to be tested independently using @camunda8/process-test. */
startWorkers(client)

console.log('Job workers started. Waiting for jobs...\n')

