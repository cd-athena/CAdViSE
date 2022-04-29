const express = require('express')
const fs = require('fs')
const app = express()
const AWS = require('aws-sdk')
AWS.config.update({ region: 'eu-central-1' })
const dynamoDb = new AWS.DynamoDB.DocumentClient()
const axios = require('axios')
const { v4: uuidv4 } = require('uuid')
const { serverIp, id } = require('./config.json')

app.get('/:anything', (request, response) => {
  response.send('')
})

app.get('/player/:playerName/asset/:assetName', async (request, response) => {
  const {playerName, assetName} = request.params
  fs.createReadStream('player/' + playerName + '/' + assetName).pipe(response)
})

app.get('/player/:playerName', async (request, response) => {
  const { playerName } = request.params
  fs.createReadStream('player/' + playerName + '/index.html').pipe(response)
})

app.get('/dataset/:title/:fileName', async (request, response) => {
  const { title, fileName } = request.params
  const { playerABR } = request.query
  const BASEURL = 'http://' + serverIp + '/'

  try {
    await log(playerABR, 'requesting', title, fileName)
  } catch (error) {
    return response.send('Failed to record the log: ' + JSON.stringify(error))
  }

  axios({
    method: 'get',
    url: BASEURL + title + '/' + fileName
  }).then((serverResponse) => {
    const manifest = serverResponse.data.replace(/queryString/g, 'playerABR=' + playerABR)
    response.send(manifest)
  }).catch(console.error)
})

app.get('/dataset/:title/:filePath/:fileName', async (request, response) => {
  const { title, filePath, fileName } = request.params
  const { playerABR } = request.query
  const BASEURL = 'http://' + serverIp + '/'

  try {
    await log(playerABR, 'requesting', title, filePath + '/' + fileName)
  } catch (error) {
    return response.send('Failed to record the log: ' + JSON.stringify(error))
  }

  axios({
    method: 'get',
    url: BASEURL + title + '/' + filePath + '/' + fileName,
    responseType: 'stream'
  }).then((serverResponse) => {
    serverResponse.data.pipe(response)
  }).catch(console.error)
})

app.get('/log/:title/:eventName', async (request, response) => {
  const { title, eventName } = request.params
  const { playerABR } = request.query

  try {
    await log(playerABR, 'event', title, eventName)
  } catch (error) {
    return response.send('Failed to record the log: ' + JSON.stringify(error))
  }

  response.send('ok')
})

app.listen(80, () => {
  console.log('Listening on port 80')
})

const log = async (playerABR, action, title, name) => {
  return dynamoDb.put({
    TableName: 'ppt-logs',
    Item: {
      id: uuidv4(),
      experimentId: id,
      time: (new Date()).toISOString(),
      playerABR,
      action,
      title,
      name
    }
  }).promise()
}
