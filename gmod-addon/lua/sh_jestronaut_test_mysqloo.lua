describe('MySQLOO async tests', function()
    itAsync('should connect to the database', function(done)
        print('Connecting to the database')
        local db = mysqloo.connect('127.0.0.1', 'root', '', 'blackbox_experiment', 3306)

        db.onConnected = function()
            print('Connected to the database')
            expect(db:status()):toBe(mysqloo.DATABASE_CONNECTED)
            db:disconnect()
            done()
        end

        db:connect()
    end)
end)
