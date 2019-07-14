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

  def sm_initialize(session, send_pid)
    expect(session.send_message_sync(
      kernel,
      Lakebed::CMIF::Message.build_rq(INITIALIZE) do
        pid(send_pid)
      end)).to reply_ok
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

  def service_name(name)
    name.ljust(8, 0.chr).unpack("Q<")[0]
  end
  
  it "accepts connections to sm:" do
    connect
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
        name = service_name("sm:m")
        fields = session.send_message_sync(
          kernel,
          Lakebed::CMIF::Message.build_rq(1) do
            u64(name)
          end) do |r|
          move_handle(:sess)
        end
        expect(fields[:sess]).to be_a(Lakebed::HIPC::Session::Client)
      end
    end
  end

  it "replies to GetService for sm:m" do
    session = connect
    sm_initialize(session, 1)
    name = service_name("sm:m")
    
    expect(
      session.send_message_sync(
        kernel,
        Lakebed::CMIF::Message.build_rq(1) do
          u64(name)
        end)).to reply_ok
  end
end
