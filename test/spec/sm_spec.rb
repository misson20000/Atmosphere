require "lakebed"

RSpec.describe "sm" do
  INITIALIZE = 0
  GET_SERVICE = 1
  REGISTER_SERVICE = 2
  UNREGISTER_SERVICE = 3
  
  before do
    load_module("sm").start
  end

  it "reaches startup without crashing" do
    kernel.continue
  end

  def connect(require_accept=true)
    session = nil
    kernel.continue
    session = kernel.named_ports["sm:"].connect
    if require_accept then
      kernel.continue
      expect(session.accepted).to be_truthy
    end
    Lakebed::CMIF::ClientSessionObject.new(session.client)
  end

  def service_name(name)
    name.ljust(8, 0.chr).unpack("Q<")[0]
  end
  
  def sm_initialize(session, send_pid)
    expect(session.send_message_sync(
      kernel,
      Lakebed::CMIF::Message.build_rq(INITIALIZE) do
        pid(send_pid)
      end)).to reply_ok
  end

  def sm_get_service(session, name)
    sname = service_name(name)
    session.send_message_sync(
      kernel,
      Lakebed::CMIF::Message.build_rq(GET_SERVICE) do
        u64(sname)
      end) do
      move_handle(:session, Lakebed::HIPC::Session::Client)
    end[:session]
  end

  def sm_register_service(session, name, is_light, max_sessions)
    sname = service_name(name)
    session.send_message_sync(
      kernel,
      Lakebed::CMIF::Message.build_rq(REGISTER_SERVICE) do
        u64(sname)
        u8(is_light ? 1 : 0)
        u32(max_sessions)
      end) do
      move_handle(:port, Lakebed::HIPC::Port::Server)
    end[:port]
  end

  def sm_unregister_service(session, name)
    sname = service_name(name)
    session.send_message_sync(
      kernel,
      Lakebed::CMIF::Message.build_rq(UNREGISTER_SERVICE) do
        u64(sname)
      end) do
    end
  end

  it "accepts connections to sm:" do
    connect
  end

  it "closes connections properly" do
    connect.close_sync(kernel)
  end
  
  it "responds to Initialize" do
    sm_initialize(connect, 0)
  end
  
  describe "without initialization" do
    if StratosphereHelpers.environment.is_ams? ||
       StratosphereHelpers.environment.target_firmware.numeric >= 201392178 then
      # no smhax
      it "replies to GetService with 0x415" do
        session = connect
        name = service_name("blabla")
        expect(
          session.send_message_sync(
            kernel,
            Lakebed::CMIF::Message.build_rq(GET_SERVICE) do
              u64(name)
            end)).to reply_with_error(0x415)
      end

      it "replies to RegisterService with 0x415" do
        session = connect
        name = service_name("blabla")
        expect(
          session.send_message_sync(
            kernel,
            Lakebed::CMIF::Message.build_rq(REGISTER_SERVICE) do
              u64(name)
              u32(0)
              u8(0)
            end)).to reply_with_error(0x415)
      end

      it "replies to UnregisterService with 0x415" do
        session = connect
        name = service_name("blabla")
        expect(
          session.send_message_sync(
            kernel,
            Lakebed::CMIF::Message.build_rq(UNREGISTER_SERVICE) do
              u64(name)
            end)).to reply_with_error(0x415)
      end
    else
      it "is vulnerable to smhax" do
        session = connect
        sm_get_service(session, "sm:m")
      end
    end
  end

  describe "with KIP rights" do
    it "replies OK to GetService for sm:m" do
      session = connect
      sm_initialize(session, 1)
      sm_get_service(session, "sm:m")
    end

    it "blocks GetService for non-registered services" do
      session = connect
      sm_initialize(session, 1)
      name = service_name("hello")

      session.send_message(
        Lakebed::CMIF::Message.build_rq(GET_SERVICE) do
          u64(name)
        end) do
        fail "should not reply"
      end
      
      kernel.continue
    end

    describe "RegisterService" do
      it "works" do
        session = connect
        sm_initialize(session, 1)
        port = sm_register_service(session, "hello", false, 32)
        expect(port.port.max_sessions).to eq(32)
        expect(port.is_signaled?).to be_falsey
      end

      it "fails with 0x815 if the service is already registered" do
        session = connect
        sm_initialize(session, 1)
        sm_register_service(session, "hello", false, 32)
        name = service_name("hello")
        expect(
          session.send_message_sync(
            kernel,
            Lakebed::CMIF::Message.build_rq(REGISTER_SERVICE) do
              u64(name)
              u8(0)
              u32(32)
            end)).to reply_with_error(0x815)
      end

      it "signals the server port when someone connects" do
        session = connect
        sm_initialize(session, 1)
        port = sm_register_service(session, "hello", false, 32)
        expect(port.port.max_sessions).to eq(32)
        expect(port.is_signaled?).to be_falsey

        cl = sm_get_service(session, "hello")
        expect(port.is_signaled?).to be_truthy
        expect(port.accept.session).to eq(cl.session)
      end
      
      it "resumes deferred GetService requests" do
        session1 = connect
        sm_initialize(session1, 1)
        session2 = connect
        sm_initialize(session2, 1)

        should_respond = false
        client_session = nil
        name = service_name("hello")
        session2.send_message(
          Lakebed::CMIF::Message.build_rq(GET_SERVICE) do
            u64(name)
          end) do |r|
          if !should_respond then
            fail "sm responded early"
          end
          client_session = r.unpack do
            move_handle(:session, Lakebed::HIPC::Session::Client)            
          end[:session]
        end

        kernel.continue

        should_respond = true
        port = sm_register_service(session1, "hello", false, 32)
        expect(port.is_signaled?).to be_truthy
        expect(client_session).not_to be_nil
        expect(port.accept.session).to eq(client_session.session)
      end
    end

    describe "UnregisterService" do
      it "fails with 0xe15 on services that are not registered" do
        session = connect
        sm_initialize(session, 1)
        name = service_name("hello")
        expect(
          session.send_message_sync(
            kernel,
            Lakebed::CMIF::Message.build_rq(UNREGISTER_SERVICE) do
              u64(name)
            end)).to reply_with_error(0xe15)
      end

      it "closes the client end of the port" do
        session = connect
        sm_initialize(session, 1)
        name = service_name("hello")
        server_port = sm_register_service(session, "hello", false, 32)
        sm_unregister_service(session, "hello")
        expect(server_port.port.client.closed).to be_truthy
      end
      
      it "causes subsequent GetService calls to fail with 0xe15" do
        session = connect
        sm_initialize(session, 1)
        name = service_name("hello")
        sm_register_service(session, "hello", false, 32)
        sm_unregister_service(session, "hello")
        expect(
          session.send_message_sync(
            kernel,
            Lakebed::CMIF::Message.build_rq(UNREGISTER_SERVICE) do
              u64(name)
            end)).to reply_with_error(0xe15)
      end
    end
  end
end
