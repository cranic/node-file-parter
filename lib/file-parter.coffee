# File Parter main class
# 
# @author Cranic Tecnologia
# @version 0.0.1
# @date 2012-07-28

crypto = require 'crypto'
fs = require 'fs'
async = require 'async'
EventEmitter = require('events').EventEmitter

class fileParter extends EventEmitter

	protect = 
		algo : null
		size : null
		stat : null
		crypto : null

	error = 
		"UNKNOWNALGO" : "Unknown hash algorithm initialized in constructor."
		"UNKNOWNFILE" : "The file do not exist or could not be accessed."
		"NOTAFILE" : "The path it's not a file."

	validate = (file, callback) ->
		process.nextTick ->
			try
				cryp = crypto.createHash protect.algo
			catch e
				callback informer "UNKNOWNALGO"
			finally
				if cryp
					fs.stat file, (err, stat) ->
						if err
							callback informer "UNKNOWNFILE"
						else if stat.isFile() != true
							callback informer "NOTAFILE"
						else
							protect.stat = stat
							callback null

	worker = (file, start, end, callback) ->
		process.nextTick ->
			options = 
				"start" : start
				"end" : end

			hash = crypto.createHash protect.algo
			file = fs.createReadStream file, options

			file.on 'data', (data) ->
				hash.update data

			file.on 'end', ->
				file.destroy()
				callback null,
					"start" : start
					"end" : end 
					"hash" : hash.digest 'hex'

	informer = (errno) ->
		if typeof error[errno] != 'undefined'
			err = new Error error[errno]
			err['errno'] = error[errno]
		else
			err = new Error "Unknown error."
			err['errno'] = "UNKNOWN"			

	constructor : (algo, size, file) ->
		that = @
		protect.algo = algo
		protect.size = size

		process.nextTick ->
			validate file, (err) ->
				if err
					that.emit 'error', err
				else
					startTime = new Date().getTime()
					start = 0;
					end = 0;
					stop = false
					pieces = 0;
					lastHash = null

					proc = ->
						process.nextTick ->
							if stop
								final()
							else
								pieces++
								end = start + protect.size
								if end > protect.stat.size
									stop = true
									end = protect.stat.size
								worker file, start, end, (err, data) ->
									that.emit 'data',
										"start" : start
										"end" : end
										"hash" : data.hash
									lastHash = crypto.createHash(protect.algo).update(lastHash + data.hash).digest 'hex'
									start = end + 1
									proc()
					proc()

					final = (err) ->
						if err
							that.emit 'error', err

						that.emit 'end',
							"file" : file
							"length" : protect.stat.size
							"pieces" : pieces
							"hash" : lastHash
							"time" : new Date().getTime() - startTime

module.exports = fileParter

