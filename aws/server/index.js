const express = require('express')
const fs = require('fs')
const app = express()

app.get('/6sec/:fileName', (request, response) => {
  const { fileName } = request.params
  console.log('Serving', fileName)
  fs.createReadStream('dataset/6sec/' + fileName).pipe(response)
})

app.get('/6sec/:filePath/:fileName', (request, response) => {
  const { filePath, fileName } = request.params
  console.log('Serving', filePath, fileName)
  fs.createReadStream('dataset/6sec/' + filePath + '/' + fileName).pipe(response)
})

app.listen(80, () => {
  console.log('Listening on port 80')
})
