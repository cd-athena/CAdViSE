const express = require('express')
const fs = require('fs')
const app = express()
const AWS = require('aws-sdk')
AWS.config.update({ region: 'eu-central-1' })
const dynamoDb = new AWS.DynamoDB.DocumentClient()
const axios = require('axios')
const { v4: uuidv4 } = require('uuid')
let { serverIp, id } = require('./config.json')
serverIp = 'localhost:8080'

app.use((request, response, next) => {
  response.header('Access-Control-Allow-Origin', '*')
  response.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept')
  console.log(request.params, "here")
  next()
})

app.get('/:anything', (request, response) => {
  response.send('')
})

app.get('/player/:playerName', async (request, response) => {
  const { playerName } = request.params
  await log('requesting ' + playerName)
  fs.createReadStream('player/' + playerName + '/index.html').pipe(response)
})

app.get('/4sec/:fileName', async (request, response) => {
  const { fileName } = request.params
  const BASEURL = 'http://' + serverIp + '/'
  await log('requesting ' + fileName)

  axios({
    method: 'get',
    url: BASEURL + '4sec/' + fileName,
    responseType: 'stream'
  }).then((serverResponse) => {
    serverResponse.data.pipe(response)
  }).catch(console.error)
})

app.get('/4sec/:filePath/:fileName', async (request, response) => {
  const { filePath, fileName } = request.params
  const BASEURL = 'http://' + serverIp + '/'
  await log('requesting ' + filePath + '/' + fileName)

  axios({
    method: 'get',
    url: BASEURL + '4sec/' + filePath + '/' + fileName,
    responseType: 'stream'
  }).then((serverResponse) => {
    serverResponse.data.pipe(response)
  }).catch(console.error)
})

app.get('/log/:eventName', async (request, response) => {
  const { eventName } = request.params
  await log(eventName)
})

app.listen(80, () => {
  console.log('Listening on port 80')
})

const log = async (event) => {
  await dynamoDb.put({
    TableName: 'ppt-logs',
    Item: {
      id: uuidv4(),
      experimentId: id,
      time: new Date().toISOString(),
      event: event
    }
  }).promise()
}
