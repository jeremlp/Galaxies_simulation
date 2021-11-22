using GLMakie
using Random, Distributions
using LinearAlgebra
using Colors, ColorSchemeTools
using ColorSchemes

const N = 8000
const Vcoef = 100
const Poscoef = 50
const Zoom = 3
const Tmax = 1050 #500
const ratio = 0.25
function init()
    d = Normal()
    println("Threads: ",Threads.nthreads())
    
    pos = Observable(GLMakie.Point3f0[])
    colors = Observable(Float32[])
    v = Observable(GLMakie.Point3f0[])
    push!(pos[], Point3f0(0, 0, 0))
    push!(v[], Point3f0(0, 0, 0))
    push!(colors[], 0)
    println(typeof(colors))
    for _ in 1:(N-1)
        i,j,k = rand(d)*Poscoef,rand(d)*Poscoef,rand(d)*5
        score = sqrt(i*i + j*j)
        if (score < 5000)
            alpha = atan(i,j)
            vx = sin(alpha-pi*0.5)*Vcoef
            vy = cos(alpha-pi*0.5)*Vcoef
            push!(pos[], Point3f0(i, j, k))
            push!(v[], Point3f0(vx, vy, 0))
            push!(colors[], score)
        end
    end
    
    Neff = length(pos[])
    println("Neff : ", Neff)
    println("====================")
    set_theme!(theme_black())
   
    fig, ax, p = GLMakie.meshscatter(pos,markersize = 0.5, color = colors, camera = cam3d!,show_axis=false, colormap = ColorSchemes.ice.colors,) #show_axis=false
    cam = cameracontrols(ax.scene)
    
    #limits!(-Poscoef*Zoom,Poscoef*Zoom,-Poscoef*Zoom,Poscoef*Zoom, -10,10)
    display(fig)
    sleep(1)
    SIMU(pos,v,colors,Neff,fig,ax,cam)
end
function SIMU(pos,v,colors,Neff, fig,ax, cam)
    GLMakie.record(fig, string("GLGalaxyV83D",Neff,".mp4"), 1:Tmax) do t
        pos_temp = copy(pos)
        v_temp = copy(v)
        timer = @elapsed Threads.@threads for i in 1:Neff
            pos_temp, v_temp, colors = getAcc(i,pos,v, pos_temp, v_temp, colors,Neff)
        end
        GLMakie.rotate!(ax.scene, 0.01*t)
        
        #cam.lookat[] = Vec3f0(0,0,-1)
        #cam.eyeposition[] = Point3f0(0,0,5)
        #update_cam!(ax.scene)
        v[] = v_temp[]
        pos[] = pos_temp[]
        notify.((pos,colors))
        println(t," Neff: ",Neff, "- Time : ", round(timer*1000,digits=2)," ms", " ", (round(1/timer))," FPS")
    end
    
end
function isOutside(p)
    return norm(p) > 1.41*Poscoef*Zoom
end

function getAcc(i,pos,v,pos_temp, v_temp, colors,Neff)

    acc_tot = [0,0,0]
    p1 = pos[][i]
    v1 = v[][i]
    
    for j in 1:convert(Int64, round(Neff*ratio, digits=0))
        if i == j
            continue            
        end
        vect = pos[][j] - p1
        d = norm(vect)

        acc = 1500 /(d*d + 2)
        acc_tot += acc*(vect)/d

    end
    dt = 0.001
    
    v1+= acc_tot * dt
    p1 += v1 *dt
    colors[][i] = log(norm(acc_tot))

    pos_temp[][i] = GLMakie.Point3f0(p1)
    v_temp[][i] = GLMakie.Point3f0(v1) 
    return pos_temp, v_temp, colors
end


init()